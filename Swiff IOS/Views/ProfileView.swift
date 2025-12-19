//
//  ProfileView.swift
//  Swiff IOS
//
//  Redesigned profile screen with contact info, linked accounts, settings, and quick toggles
//

import SwiftUI
import PhotosUI
import Combine

// MARK: - Data Models

struct LinkedAccount: Identifiable, Codable {
    let id: UUID
    var name: String
    var last4: String
    var type: String

    init(id: UUID = UUID(), name: String, last4: String, type: String) {
        self.id = id
        self.name = name
        self.last4 = last4
        self.type = type
    }
}

struct ProfileCurrencyOption: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let symbol: String
}

// MARK: - View Model

class ProfileViewModel: ObservableObject {
    @Published var selectedCurrency = "USD"

    @Published var notifications: [String: Bool] = [
        "transactions": true,
        "security": true,
        "marketing": false,
        "weekly": true
    ]

    @Published var accounts: [LinkedAccount] = []

    @Published var security: [String: Bool] = [
        "twoFactor": false,
        "biometric": false,
        "loginAlerts": true
    ]

    @Published var appSettings: [String: Bool] = [
        "darkMode": false,
        "compactView": false,
        "hideBalances": false
    ]

    let currencies: [ProfileCurrencyOption] = [
        ProfileCurrencyOption(code: "USD", name: "US Dollar", symbol: "$"),
        ProfileCurrencyOption(code: "EUR", name: "Euro", symbol: "€"),
        ProfileCurrencyOption(code: "GBP", name: "British Pound", symbol: "£"),
        ProfileCurrencyOption(code: "INR", name: "Indian Rupee", symbol: "₹"),
        ProfileCurrencyOption(code: "JPY", name: "Japanese Yen", symbol: "¥"),
        ProfileCurrencyOption(code: "CAD", name: "Canadian Dollar", symbol: "CA$"),
        ProfileCurrencyOption(code: "AUD", name: "Australian Dollar", symbol: "A$")
    ]

    private let accountsKey = "LinkedAccounts"
    private let currencyKey = "SelectedCurrency"
    private let notificationsKey = "NotificationSettings"
    private let securityKey = "SecuritySettings"
    private let appSettingsKey = "AppSettings"

    init() {
        loadSettings()
    }

    func addAccount(name: String, number: String, type: String) {
        let last4 = String(number.suffix(4))
        let newAccount = LinkedAccount(name: name, last4: last4, type: type)
        accounts.append(newAccount)
        saveAccounts()
    }

    func removeAccount(id: UUID) {
        accounts.removeAll { $0.id == id }
        saveAccounts()
    }

    func getCurrencyDisplay() -> String {
        if let currency = currencies.first(where: { $0.code == selectedCurrency }) {
            return "\(currency.name) (\(currency.symbol))"
        }
        return selectedCurrency
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([LinkedAccount].self, from: data) {
            accounts = decoded
        }

        if let currency = defaults.string(forKey: currencyKey) {
            selectedCurrency = currency
        }

        if let notifData = defaults.dictionary(forKey: notificationsKey) as? [String: Bool] {
            notifications = notifData
        }

        if let secData = defaults.dictionary(forKey: securityKey) as? [String: Bool] {
            security = secData
        }

        if let appData = defaults.dictionary(forKey: appSettingsKey) as? [String: Bool] {
            appSettings = appData
        }
    }

    private func saveAccounts() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: accountsKey)
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(selectedCurrency, forKey: currencyKey)
        defaults.set(notifications, forKey: notificationsKey)
        defaults.set(security, forKey: securityKey)
        defaults.set(appSettings, forKey: appSettingsKey)
    }
}

// MARK: - Main Profile View

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var toastManager = ToastManager.shared

    // Sheet states
    @State private var showEditName = false
    @State private var showEditEmail = false
    @State private var showEditPhone = false
    @State private var showChangePhoto = false
    @State private var showCurrencyPicker = false
    @State private var showAddAccount = false
    @State private var showAccountDetails = false
    @State private var showSecurity = false
    @State private var showNotifications = false
    @State private var showPaymentMethods = false
    @State private var showAppSettings = false
    @State private var showSignOutAlert = false
    @State private var showChangePassword = false
    @State private var showDeleteDataAlert = false

    @State private var selectedAccount: LinkedAccount?

    // App version
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    // Member since formatted
    private var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: profileManager.profile.createdDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Profile")
                            .font(.spotifyDisplayMedium)
                            .foregroundColor(.wisePrimaryText)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Profile Card
                    profileCard

                    // Contact Information
                    contactSection

                    // Preferences
                    preferencesSection

                    // Linked Accounts
                    linkedAccountsSection

                    // Settings
                    settingsSection

                    // Quick Settings
                    quickSettingsSection

                    // Sign Out
                    signOutButton

                    // Version
                    Text(appVersion)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                }
                .padding(.horizontal)
            }
            .background(Color.wiseGroupedBackground)
        }

        // MARK: - Sheets
        .sheet(isPresented: $showEditName) {
            ProfileEditFieldSheet(
                title: "Edit Name",
                value: Binding(
                    get: { profileManager.profile.name },
                    set: { newValue in
                        var profile = profileManager.profile
                        profile.name = newValue
                        profileManager.updateProfile(profile)
                    }
                ),
                placeholder: "Enter name",
                keyboardType: .default
            )
        }
        .sheet(isPresented: $showEditEmail) {
            ProfileEditFieldSheet(
                title: "Edit Email",
                value: Binding(
                    get: { profileManager.profile.email },
                    set: { newValue in
                        var profile = profileManager.profile
                        profile.email = newValue
                        profileManager.updateProfile(profile)
                    }
                ),
                placeholder: "Enter email",
                keyboardType: .emailAddress
            )
        }
        .sheet(isPresented: $showEditPhone) {
            ProfileEditFieldSheet(
                title: "Edit Phone",
                value: Binding(
                    get: { profileManager.profile.phone },
                    set: { newValue in
                        var profile = profileManager.profile
                        profile.phone = newValue
                        profileManager.updateProfile(profile)
                    }
                ),
                placeholder: "Enter phone",
                keyboardType: .phonePad
            )
        }
        .sheet(isPresented: $showChangePhoto) {
            ProfileChangePhotoSheet(profileManager: profileManager)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            ProfileCurrencyPickerSheet(
                currencies: viewModel.currencies,
                selectedCurrency: $viewModel.selectedCurrency,
                onSelect: { viewModel.saveSettings() }
            )
        }
        .sheet(isPresented: $showAddAccount) {
            ProfileAddAccountSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showAccountDetails) {
            if let account = selectedAccount {
                ProfileAccountDetailsSheet(
                    account: account,
                    onRemove: {
                        viewModel.removeAccount(id: account.id)
                        showAccountDetails = false
                    }
                )
            }
        }
        .sheet(isPresented: $showSecurity) {
            ProfileSecuritySheet(
                security: $viewModel.security,
                showChangePassword: $showChangePassword,
                onSave: { viewModel.saveSettings() }
            )
        }
        .sheet(isPresented: $showChangePassword) {
            ProfileChangePasswordSheet()
        }
        .sheet(isPresented: $showNotifications) {
            ProfileNotificationsSheet(
                notifications: $viewModel.notifications,
                onSave: { viewModel.saveSettings() }
            )
        }
        .sheet(isPresented: $showPaymentMethods) {
            ProfilePaymentMethodsSheet(
                accounts: viewModel.accounts,
                onAddAccount: {
                    showPaymentMethods = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAddAccount = true
                    }
                }
            )
        }
        .sheet(isPresented: $showAppSettings) {
            ProfileAppSettingsSheet(
                appSettings: $viewModel.appSettings,
                onSave: { viewModel.saveSettings() }
            )
        }
        .alert("Sign Out?", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                HapticManager.shared.notification(.success)
                toastManager.showInfo("Signed out successfully")
            }
        } message: {
            Text("Are you sure you want to sign out of your account?")
        }
        .alert("Delete All Data?", isPresented: $showDeleteDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                performDeleteAllData()
            }
        } message: {
            Text("This will permanently delete all your data. This action cannot be undone.")
        }
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        VStack {
            HStack(spacing: 16) {
                // Avatar with camera button
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(
                        avatarType: profileManager.profile.avatarType,
                        size: .xlarge,
                        style: .solid
                    )

                    Button(action: {
                        HapticManager.shared.impact(.light)
                        showChangePhoto = true
                    }) {
                        Circle()
                            .fill(Color.wiseCardBackground)
                            .frame(width: 28, height: 28)
                            .shadow(color: .wiseShadowColor, radius: 2, y: 1)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.wiseSecondaryText)
                            )
                    }
                    .offset(x: 4, y: 4)
                }

                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(profileManager.profile.name.isEmpty ? "User" : profileManager.profile.name)
                            .font(.spotifyHeadingLarge)
                            .foregroundColor(.wisePrimaryText)

                        Button(action: {
                            HapticManager.shared.impact(.light)
                            showEditName = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }

                    Text("Member since \(memberSince)")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()
            }
            .padding(20)
        }
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
    }

    // MARK: - Contact Section
    private var contactSection: some View {
        VStack(spacing: 0) {
            ProfileSectionHeader(title: "CONTACT INFORMATION")

            VStack(spacing: 0) {
                Button(action: {
                    HapticManager.shared.impact(.light)
                    showEditEmail = true
                }) {
                    ProfileContactRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: profileManager.profile.email.isEmpty ? "Add email" : profileManager.profile.email,
                        isVerified: !profileManager.profile.email.isEmpty,
                        showDivider: true
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    HapticManager.shared.impact(.light)
                    showEditPhone = true
                }) {
                    ProfileContactRow(
                        icon: "phone.fill",
                        label: "Phone",
                        value: profileManager.profile.phone.isEmpty ? "Add phone" : profileManager.profile.phone,
                        isVerified: !profileManager.profile.phone.isEmpty,
                        showDivider: false
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(spacing: 0) {
            ProfileSectionHeader(title: "PREFERENCES")

            VStack(spacing: 0) {
                NavigationLink(destination: ProfileSettingsPage()) {
                    PreferencesSettingsRow(
                        icon: "person.fill",
                        iconColor: .wiseBlue,
                        title: "Profile Settings",
                        subtitle: "Profile, notifications & storage",
                        showDivider: true
                    )
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: PrivacySecurityPage()) {
                    PreferencesSettingsRow(
                        icon: "lock.shield.fill",
                        iconColor: .wiseForestGreen,
                        title: "Privacy & Security",
                        subtitle: "Control access and security settings",
                        showDivider: true
                    )
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: AnalyticsInsightsPage().environmentObject(dataManager)) {
                    PreferencesSettingsRow(
                        icon: "arrow.up.forward.square.fill",
                        iconColor: .wiseBrightGreen,
                        title: "Analytics & Insights",
                        subtitle: "View spending insights and trends",
                        showDivider: true
                    )
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: HelpSupportPage()) {
                    PreferencesSettingsRow(
                        icon: "questionmark.circle.fill",
                        iconColor: .wiseOrange,
                        title: "Help & Support",
                        subtitle: "Get help using Swiff",
                        showDivider: false
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Linked Accounts Section
    private var linkedAccountsSection: some View {
        VStack(spacing: 0) {
            ProfileSectionHeader(title: "LINKED ACCOUNTS")

            VStack(spacing: 0) {
                if viewModel.accounts.isEmpty {
                    Text("No accounts linked yet")
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wiseSecondaryText)
                        .padding(.vertical, 24)
                } else {
                    ForEach(Array(viewModel.accounts.enumerated()), id: \.element.id) { index, account in
                        Button(action: {
                            HapticManager.shared.impact(.light)
                            selectedAccount = account
                            showAccountDetails = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.wiseSecondaryText)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name)
                                        .font(.spotifyBodyLarge)
                                        .foregroundColor(.wisePrimaryText)
                                    Text("•••• \(account.last4)")
                                        .font(.spotifyBodySmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.wiseSecondaryText.opacity(0.5))
                            }
                            .padding(16)
                            .background(Color.wiseCardBackground)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if index < viewModel.accounts.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }

                Divider()

                Button(action: {
                    HapticManager.shared.impact(.light)
                    showAddAccount = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Account")
                            .font(.spotifyBodyLarge)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.wiseBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 0) {
            ProfileSectionHeader(title: "SETTINGS")

            VStack(spacing: 0) {
                ProfileSettingsRow(
                    icon: "shield.fill",
                    title: "Security",
                    subtitle: viewModel.security["twoFactor"] == true ? "2FA enabled" : nil,
                    showDivider: true,
                    action: {
                        HapticManager.shared.impact(.light)
                        showSecurity = true
                    }
                )

                ProfileSettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: nil,
                    showDivider: true,
                    action: {
                        HapticManager.shared.impact(.light)
                        showNotifications = true
                    }
                )

                ProfileSettingsRow(
                    icon: "wallet.pass.fill",
                    title: "Payment Methods",
                    subtitle: nil,
                    showDivider: true,
                    action: {
                        HapticManager.shared.impact(.light)
                        showPaymentMethods = true
                    }
                )

                ProfileSettingsRow(
                    icon: "gearshape.fill",
                    title: "App Settings",
                    subtitle: nil,
                    showDivider: false,
                    action: {
                        HapticManager.shared.impact(.light)
                        showAppSettings = true
                    }
                )
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Quick Settings Section
    private var quickSettingsSection: some View {
        VStack(spacing: 0) {
            ProfileSectionHeader(title: "QUICK SETTINGS")

            VStack(spacing: 0) {
                ProfileToggleRow(
                    title: "Transaction alerts",
                    isOn: Binding(
                        get: { viewModel.notifications["transactions"] ?? false },
                        set: {
                            viewModel.notifications["transactions"] = $0
                            viewModel.saveSettings()
                        }
                    ),
                    showDivider: true
                )

                ProfileToggleRow(
                    title: "Security alerts",
                    isOn: Binding(
                        get: { viewModel.notifications["security"] ?? false },
                        set: {
                            viewModel.notifications["security"] = $0
                            viewModel.saveSettings()
                        }
                    ),
                    showDivider: true
                )

                ProfileToggleRow(
                    title: "Weekly summary",
                    isOn: Binding(
                        get: { viewModel.notifications["weekly"] ?? false },
                        set: {
                            viewModel.notifications["weekly"] = $0
                            viewModel.saveSettings()
                        }
                    ),
                    showDivider: true
                )

                ProfileToggleRow(
                    title: "Promotions",
                    isOn: Binding(
                        get: { viewModel.notifications["marketing"] ?? false },
                        set: {
                            viewModel.notifications["marketing"] = $0
                            viewModel.saveSettings()
                        }
                    ),
                    showDivider: false
                )
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            showSignOutAlert = true
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18))
                Text("Sign Out")
                    .font(.spotifyBodyLarge)
                    .fontWeight(.medium)
            }
            .foregroundColor(.wiseError)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Functions
    private func performDeleteAllData() {
        do {
            try dataManager.clearAllData()
            HapticManager.shared.notification(.success)
            toastManager.showSuccess("All data deleted successfully")
        } catch {
            HapticManager.shared.notification(.error)
            toastManager.showError("Failed to delete data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Reusable Components

struct ProfileSectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
        .padding(.top, 8)
    }
}

struct ProfileContactRow: View {
    let icon: String
    let label: String
    let value: String
    let isVerified: Bool
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.wiseSecondaryText)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                    Text(value)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                }

                Spacer()

                if isVerified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .medium))
                        Text("Verified")
                            .font(.spotifyCaptionLarge)
                    }
                    .foregroundColor(.wiseSuccess)
                }
            }
            .padding(16)

            if showDivider {
                Divider().padding(.leading, 52)
            }
        }
    }
}

struct ProfileSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let showDivider: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.wiseSecondaryText)
                        .frame(width: 24)

                    Text(title)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)

                    Spacer()

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.wiseSecondaryText.opacity(0.5))
                }
                .padding(16)

                if showDivider {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.wisePrimaryButton)
            }
            .padding(16)

            if showDivider {
                Divider().padding(.leading, 16)
            }
        }
    }
}

// MARK: - Sheet Views

struct ProfileEditFieldSheet: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let keyboardType: UIKeyboardType

    @Environment(\.dismiss) private var dismiss
    @State private var tempValue: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField(placeholder, text: $tempValue)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(.wisePrimaryText)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseBorder.opacity(0.3))
                            .stroke(Color.wiseBorder, lineWidth: 1)
                    )
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .padding(.horizontal)
                    .padding(.top, 20)

                Spacer()
            }
            .background(Color.wiseGroupedBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        value = tempValue
                        HapticManager.shared.notification(.success)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryButton)
                }
            }
        }
        .onAppear {
            tempValue = value
        }
    }
}

struct ProfileChangePhotoSheet: View {
    @ObservedObject var profileManager: UserProfileManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera")
                            .font(.system(size: 32))
                            .foregroundColor(.wiseSecondaryText)
                        Text("Click to upload or drag and drop")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wiseSecondaryText)
                        Text("PNG, JPG up to 5MB")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(.wiseBorder)
                    )
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Button(action: {
                    var profile = profileManager.profile
                    profile.avatarType = .initials(profile.initials, colorIndex: 0)
                    profileManager.updateProfile(profile)
                    HapticManager.shared.notification(.success)
                    dismiss()
                }) {
                    Text("Remove Photo")
                        .font(.spotifyBodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(.wisePrimaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.wiseSecondaryButton)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.wiseGroupedBackground)
            .navigationTitle("Change Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                if let item = newValue,
                   let data = try? await item.loadTransferable(type: Data.self) {
                    var profile = profileManager.profile
                    profile.avatarType = .photo(data)
                    profileManager.updateProfile(profile)
                    HapticManager.shared.notification(.success)
                    dismiss()
                }
            }
        }
    }
}

struct ProfileCurrencyPickerSheet: View {
    let currencies: [ProfileCurrencyOption]
    @Binding var selectedCurrency: String
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(currencies) { currency in
                    Button(action: {
                        selectedCurrency = currency.code
                        onSelect()
                        HapticManager.shared.selection()
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currency.name)
                                    .font(.spotifyBodyLarge)
                                    .foregroundColor(.wisePrimaryText)
                                Text("\(currency.symbol) \(currency.code)")
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wiseSecondaryText)
                            }

                            Spacer()

                            if selectedCurrency == currency.code {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.wisePrimaryButton)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.wiseGroupedBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }
}

struct ProfileAddAccountSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var accountName = ""
    @State private var accountNumber = ""
    @State private var accountType = "Bank Account"

    let accountTypes = ["Bank Account", "Credit Card", "Debit Card", "Investment Account"]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Account Name", text: $accountName)
                        .font(.spotifyBodyLarge)
                    TextField("Account Number", text: $accountNumber)
                        .font(.spotifyBodyLarge)
                        .keyboardType(.numberPad)
                    Picker("Account Type", selection: $accountType) {
                        ForEach(accountTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .font(.spotifyBodyLarge)
                }
            }
            .background(Color.wiseGroupedBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !accountName.isEmpty && !accountNumber.isEmpty {
                            viewModel.addAccount(name: accountName, number: accountNumber, type: accountType)
                            HapticManager.shared.notification(.success)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryButton)
                    .disabled(accountName.isEmpty || accountNumber.isEmpty)
                }
            }
        }
    }
}

struct ProfileAccountDetailsSheet: View {
    let account: LinkedAccount
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Name")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                        Text(account.name)
                            .font(.spotifyHeadingSmall)
                            .foregroundColor(.wisePrimaryText)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Number")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                        Text("•••• •••• •••• \(account.last4)")
                            .font(.spotifyHeadingSmall)
                            .foregroundColor(.wisePrimaryText)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                        Text(account.type)
                            .font(.spotifyHeadingSmall)
                            .foregroundColor(.wisePrimaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.wiseSecondaryButton)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 20)

                Button(action: {
                    HapticManager.shared.notification(.warning)
                    onRemove()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove Account")
                    }
                    .font(.spotifyBodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.wiseError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.wiseError.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.wiseGroupedBackground)
            .navigationTitle("Account Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }
}

struct ProfileSecuritySheet: View {
    @Binding var security: [String: Bool]
    @Binding var showChangePassword: Bool
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle(isOn: Binding(
                        get: { security["twoFactor"] ?? false },
                        set: {
                            security["twoFactor"] = $0
                            onSave()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Two-Factor Authentication")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Add extra security to your account")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wisePrimaryButton)

                    Toggle(isOn: Binding(
                        get: { security["biometric"] ?? false },
                        set: {
                            security["biometric"] = $0
                            onSave()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Biometric Login")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Use fingerprint or face recognition")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wisePrimaryButton)

                    Toggle(isOn: Binding(
                        get: { security["loginAlerts"] ?? false },
                        set: {
                            security["loginAlerts"] = $0
                            onSave()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Login Alerts")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Get notified of new logins")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wisePrimaryButton)
                }

                Section {
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showChangePassword = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.wisePrimaryText)
                            Text("Change Password")
                                .foregroundColor(.wisePrimaryText)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.wiseGroupedBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wisePrimaryButton)
                }
            }
        }
    }
}

struct ProfileChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showCurrentPassword = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        if showCurrentPassword {
                            TextField("Current Password", text: $currentPassword)
                                .font(.spotifyBodyLarge)
                        } else {
                            SecureField("Current Password", text: $currentPassword)
                                .font(.spotifyBodyLarge)
                        }
                        Button(action: { showCurrentPassword.toggle() }) {
                            Image(systemName: showCurrentPassword ? "eye.slash" : "eye")
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }

                    SecureField("New Password", text: $newPassword)
                        .font(.spotifyBodyLarge)
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .font(.spotifyBodyLarge)
                }
            }
            .background(Color.wiseGroupedBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseSecondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        HapticManager.shared.notification(.success)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.wisePrimaryButton)
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                }
            }
        }
    }
}

struct ProfileNotificationsSheet: View {
    @Binding var notifications: [String: Bool]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle(isOn: Binding(
                        get: { notifications["transactions"] ?? false },
                        set: {
                            notifications["transactions"] = $0
                            onSave()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Transaction Alerts")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Get notified for all transactions")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wisePrimaryButton)

                    Toggle(isOn: Binding(
                        get: { notifications["security"] ?? false },
                        set: {
                            notifications["security"] = $0
                            onSave()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Security Alerts")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Login attempts and suspicious activity")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wisePrimaryButton)

                    Toggle(isOn: Binding(
                        get: { notifications["weekly"] ?? false },
                        set: {
                            notifications["weekly"] = $0
                            onSave()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly Summary")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Spending insights every week")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wisePrimaryButton)

                    Toggle(isOn: Binding(
                        get: { notifications["marketing"] ?? false },
                        set: {
                            notifications["marketing"] = $0
                            onSave()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Promotions")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Offers and new features")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wisePrimaryButton)
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.wiseGroupedBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wisePrimaryButton)
                }
            }
        }
    }
}

struct ProfilePaymentMethodsSheet: View {
    let accounts: [LinkedAccount]
    let onAddAccount: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(accounts) { account in
                        HStack(spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.wiseSecondaryText)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.name)
                                    .font(.spotifyBodyLarge)
                                    .foregroundColor(.wisePrimaryText)
                                Text("•••• \(account.last4)")
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button(action: onAddAccount) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Payment Method")
                        }
                        .foregroundColor(.wiseBlue)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.wiseGroupedBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wisePrimaryButton)
                }
            }
        }
    }
}

struct ProfileAppSettingsSheet: View {
    @Binding var appSettings: [String: Bool]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle(isOn: Binding(
                        get: { appSettings["darkMode"] ?? false },
                        set: {
                            appSettings["darkMode"] = $0
                            onSave()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dark Mode")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Use dark theme")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wisePrimaryButton)

                    Toggle(isOn: Binding(
                        get: { appSettings["compactView"] ?? false },
                        set: {
                            appSettings["compactView"] = $0
                            onSave()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Compact View")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Show more items on screen")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wisePrimaryButton)

                    Toggle(isOn: Binding(
                        get: { appSettings["hideBalances"] ?? false },
                        set: {
                            appSettings["hideBalances"] = $0
                            onSave()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hide Balances")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wisePrimaryText)
                            Text("Hide amounts on home screen")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .tint(.wisePrimaryButton)
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.wiseGroupedBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wisePrimaryButton)
                }
            }
        }
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
