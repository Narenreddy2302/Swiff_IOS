//
//  ProfileView.swift
//  Swiff IOS
//
//  Redesigned profile screen with contact info, linked accounts, settings, and quick toggles
//

import Combine
import PhotosUI
import SwiftUI

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

    @Published var accounts: [LinkedAccount] = []

    @Published var security: [String: Bool] = [
        "twoFactor": false,
        "biometric": false,
        "loginAlerts": true,
    ]

    @Published var appSettings: [String: Bool] = [
        "compactView": false,
        "hideBalances": false,
    ]

    let currencies: [ProfileCurrencyOption] = [
        ProfileCurrencyOption(code: "USD", name: "US Dollar", symbol: "$"),
        ProfileCurrencyOption(code: "EUR", name: "Euro", symbol: "€"),
        ProfileCurrencyOption(code: "GBP", name: "British Pound", symbol: "£"),
        ProfileCurrencyOption(code: "INR", name: "Indian Rupee", symbol: "₹"),
        ProfileCurrencyOption(code: "JPY", name: "Japanese Yen", symbol: "¥"),
        ProfileCurrencyOption(code: "CAD", name: "Canadian Dollar", symbol: "CA$"),
        ProfileCurrencyOption(code: "AUD", name: "Australian Dollar", symbol: "A$"),
    ]

    private let accountsKey = "LinkedAccounts"
    private let currencyKey = "SelectedCurrency"

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
            let decoded = try? JSONDecoder().decode([LinkedAccount].self, from: data)
        {
            accounts = decoded
        }

        if let currency = defaults.string(forKey: currencyKey) {
            selectedCurrency = currency
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
    @StateObject private var userSettings = UserSettings.shared

    // Sheet states
    @State private var showEditName = false
    @State private var showEditEmail = false
    @State private var showEditPhone = false
    @State private var showChangePhoto = false
    @State private var showCurrencyPicker = false
    @State private var showAddAccount = false
    @State private var showAccountDetails = false
    @State private var showSecurity = false

    @State private var showPaymentMethods = false
    @State private var showAppSettings = false
    @State private var showChangePassword = false
    @State private var showDeleteDataAlert = false
    @State private var showSignOutAlert = false

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
                VStack(spacing: 24) {
                    // Header
                    ProfileHeaderView(
                        profile: profileManager.profile,
                        onEdit: {
                            HapticManager.shared.impact(.light)
                            showEditName = true
                        }
                    )
                    .padding(.top, 8)

                    // Contact Information
                    contactSection

                    // Appearance
                    appearanceSection

                    // Preferences
                    preferencesSection

                    // Linked Accounts
                    linkedAccountsSection

                    // Settings
                    settingsSection

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
            .background(Color.wiseBackground)
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
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                HapticManager.shared.notification(.success)
                toastManager.showInfo("Signed out successfully")
            }
        } message: {
            Text("Are you sure you want to sign out of your account?")
        }
        .alert("Delete All Data?", isPresented: $showDeleteDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                performDeleteAllData()
            }
        } message: {
            Text("This will permanently delete all your data. This action cannot be undone.")
        }
    }

    // MARK: - Contact Section
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONTACT INFORMATION")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .padding(.leading, 4)

            VStack(spacing: 2) {
                Button(action: {
                    HapticManager.shared.impact(.light)
                    showEditEmail = true
                }) {
                    UnifiedListRow(
                        title: "Email",
                        subtitle: profileManager.profile.email.isEmpty
                            ? "Add email" : profileManager.profile.email,
                        value: profileManager.profile.email.isEmpty ? "Add" : "Verified",
                        valueColor: profileManager.profile.email.isEmpty ? .wiseBlue : .wiseSuccess,
                        showChevron: true
                    ) {
                        UnifiedIconCircle(icon: "envelope.fill", color: .wiseBlue)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    HapticManager.shared.impact(.light)
                    showEditPhone = true
                }) {
                    UnifiedListRow(
                        title: "Phone",
                        subtitle: profileManager.profile.phone.isEmpty
                            ? "Add phone" : profileManager.profile.phone,
                        value: profileManager.profile.phone.isEmpty ? "Add" : "Verified",
                        valueColor: profileManager.profile.phone.isEmpty ? .wiseBlue : .wiseSuccess,
                        showChevron: true
                    ) {
                        UnifiedIconCircle(icon: "phone.fill", color: .wiseForestGreen)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Appearance Section
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPEARANCE")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .padding(.leading, 4)

            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    UnifiedIconCircle(icon: "circle.lefthalf.filled", color: .wisePurple)

                    Text("App Theme")
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)

                    Spacer()
                }

                Picker("Theme", selection: $userSettings.themeMode) {
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                    Text("System").tag("System")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: userSettings.themeMode) { _, _ in
                    HapticManager.shared.impact(.light)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
            )
            .subtleShadow()
        }
    }

    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREFERENCES")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .padding(.leading, 4)

            VStack(spacing: 2) {
                NavigationLink(destination: ProfileSettingsPage()) {
                    UnifiedListRow(
                        title: "Profile Settings",
                        subtitle: "Profile, notifications & storage",
                        value: "",
                        valueColor: .clear,
                        showChevron: true
                    ) {
                        UnifiedIconCircle(icon: "person.fill", color: .wiseBlue)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: PrivacySecurityPage()) {
                    UnifiedListRow(
                        title: "Privacy & Security",
                        subtitle: "Control access and security settings",
                        value: "",
                        valueColor: .clear,
                        showChevron: true
                    ) {
                        UnifiedIconCircle(icon: "lock.shield.fill", color: .wiseForestGreen)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: AnalyticsInsightsPage().environmentObject(dataManager))
                {
                    UnifiedListRow(
                        title: "Analytics & Insights",
                        subtitle: "View spending insights and trends",
                        value: "",
                        valueColor: .clear,
                        showChevron: true
                    ) {
                        UnifiedIconCircle(icon: "chart.bar.fill", color: .wiseBrightGreen)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: HelpSupportPage()) {
                    UnifiedListRow(
                        title: "Help & Support",
                        subtitle: "Get help using Swiff",
                        value: "",
                        valueColor: .clear,
                        showChevron: true
                    ) {
                        UnifiedIconCircle(icon: "questionmark.circle.fill", color: .wiseOrange)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Linked Accounts Section
    private var linkedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LINKED ACCOUNTS")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .padding(.leading, 4)

            VStack(spacing: 2) {
                if viewModel.accounts.isEmpty {
                    HStack {
                        Spacer()
                        Text("No accounts linked yet")
                            .font(.spotifyBodyLarge)
                            .foregroundColor(.wiseSecondaryText)
                            .padding(.vertical, 24)
                        Spacer()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseCardBackground)
                    )
                    .subtleShadow()
                } else {
                    ForEach(viewModel.accounts) { account in
                        Button(action: {
                            HapticManager.shared.impact(.light)
                            selectedAccount = account
                            showAccountDetails = true
                        }) {
                            UnifiedListRow(
                                title: account.name,
                                subtitle: "•••• \(account.last4)",
                                value: "",
                                valueColor: .clear,
                                showChevron: true
                            ) {
                                UnifiedIconCircle(
                                    icon: "creditcard.fill", color: .wiseSecondaryText)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Button(action: {
                    HapticManager.shared.impact(.light)
                    showAddAccount = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Add Account")
                            .font(.spotifyBodyLarge)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.wiseBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wiseCardBackground)
                    )
                    .subtleShadow()
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SETTINGS")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
                .padding(.leading, 4)

            VStack(spacing: 2) {
                Button(action: {
                    HapticManager.shared.impact(.light)
                    showSecurity = true
                }) {
                    UnifiedListRow(
                        title: "Security",
                        subtitle: viewModel.security["twoFactor"] == true
                            ? "2FA enabled" : "Security settings",
                        value: "",
                        valueColor: .clear,
                        showChevron: true
                    ) {
                        UnifiedIconCircle(icon: "shield.fill", color: .wisePurple)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    HapticManager.shared.impact(.light)
                    showPaymentMethods = true
                }) {
                    UnifiedListRow(
                        title: "Payment Methods",
                        subtitle: "Manage payment options",
                        value: "",
                        valueColor: .clear,
                        showChevron: true
                    ) {
                        UnifiedIconCircle(icon: "wallet.pass.fill", color: .wiseForestGreen)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    HapticManager.shared.impact(.light)
                    showAppSettings = true
                }) {
                    UnifiedListRow(
                        title: "App Settings",
                        subtitle: "General application settings",
                        value: "",
                        valueColor: .clear,
                        showChevron: true
                    ) {
                        UnifiedIconCircle(icon: "gearshape.fill", color: .wiseSecondaryText)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
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
                    .font(.system(size: 16, weight: .bold))
                Text("Sign Out")
                    .font(.spotifyBodyLarge)
                    .fontWeight(.medium)
            }
            .foregroundColor(.wiseError)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wiseCardBackground)
            )
            .subtleShadow()
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
                    let data = try? await item.loadTransferable(type: Data.self)
                {
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
                            viewModel.addAccount(
                                name: accountName, number: accountNumber, type: accountType)
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
                    Toggle(
                        isOn: Binding(
                            get: { security["twoFactor"] ?? false },
                            set: {
                                security["twoFactor"] = $0
                                onSave()
                            }
                        )
                    ) {
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

                    Toggle(
                        isOn: Binding(
                            get: { security["biometric"] ?? false },
                            set: {
                                security["biometric"] = $0
                                onSave()
                            }
                        )
                    ) {
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

                    Toggle(
                        isOn: Binding(
                            get: { security["loginAlerts"] ?? false },
                            set: {
                                security["loginAlerts"] = $0
                                onSave()
                            }
                        )
                    ) {
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
                    .disabled(
                        currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty
                            || newPassword != confirmPassword)
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
                    Toggle(
                        isOn: Binding(
                            get: { notifications["transactions"] ?? false },
                            set: {
                                notifications["transactions"] = $0
                                onSave()
                            }
                        )
                    ) {
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

                    Toggle(
                        isOn: Binding(
                            get: { notifications["security"] ?? false },
                            set: {
                                notifications["security"] = $0
                                onSave()
                            }
                        )
                    ) {
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

                    Toggle(
                        isOn: Binding(
                            get: { notifications["weekly"] ?? false },
                            set: {
                                notifications["weekly"] = $0
                                onSave()
                            }
                        )
                    ) {
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

                    Toggle(
                        isOn: Binding(
                            get: { notifications["marketing"] ?? false },
                            set: {
                                notifications["marketing"] = $0
                                onSave()
                            }
                        )
                    ) {
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

                    Toggle(
                        isOn: Binding(
                            get: { appSettings["compactView"] ?? false },
                            set: {
                                appSettings["compactView"] = $0
                                onSave()
                            }
                        )
                    ) {
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

                    Toggle(
                        isOn: Binding(
                            get: { appSettings["hideBalances"] ?? false },
                            set: {
                                appSettings["hideBalances"] = $0
                                onSave()
                            }
                        )
                    ) {
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

#Preview("ProfileView - Default") {
    ProfileView()
        .environmentObject(DataManager.shared)
}

#Preview("ProfileView - Dark Mode") {
    ProfileView()
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
