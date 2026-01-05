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
                    profileSection(title: "CONTACT INFORMATION") {
                        UnifiedListRowV2(
                            iconName: "envelope.fill",
                            iconColor: .wiseBlue,
                            title: "Email",
                            subtitle: profileManager.profile.email.isEmpty ? "Add email" : profileManager.profile.email,
                            value: profileManager.profile.email.isEmpty ? "Add" : "Verified",
                            valueColor: profileManager.profile.email.isEmpty ? .wiseBlue : .wiseSuccess,
                            showChevron: true,
                            onTap: {
                                HapticManager.shared.impact(.light)
                                showEditEmail = true
                            }
                        )
                        
                        Divider().padding(.leading, 76)
                        
                        UnifiedListRowV2(
                            iconName: "phone.fill",
                            iconColor: .wiseForestGreen,
                            title: "Phone",
                            subtitle: profileManager.profile.phone.isEmpty ? "Add phone" : profileManager.profile.phone,
                            value: profileManager.profile.phone.isEmpty ? "Add" : "Verified",
                            valueColor: profileManager.profile.phone.isEmpty ? .wiseBlue : .wiseSuccess,
                            showChevron: true,
                            onTap: {
                                HapticManager.shared.impact(.light)
                                showEditPhone = true
                            }
                        )
                    }

                    // Appearance
                    profileSection(title: "APPEARANCE") {
                        HStack(spacing: 12) {
                            UnifiedIconCircle(icon: "circle.lefthalf.filled", color: .wisePurple)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("App Theme")
                                    .font(.spotifyBodyLarge)
                                    .foregroundColor(.wisePrimaryText)
                                Text(userSettings.themeMode)
                                    .font(.spotifyBodySmall)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            
                            Spacer()
                            
                            Picker("Theme", selection: $userSettings.themeMode) {
                                Text("Light").tag("Light")
                                Text("Dark").tag("Dark")
                                Text("System").tag("System")
                            }
                            .labelsHidden()
                            .tint(.wiseSecondaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    // Preferences
                    profileSection(title: "PREFERENCES") {
                        NavigationLink(destination: ProfileSettingsPage()) {
                            UnifiedListRowV2(
                                iconName: "person.fill",
                                iconColor: .wiseBlue,
                                title: "Profile Settings",
                                subtitle: "Profile, notifications & storage",
                                value: "",
                                valueColor: .clear,
                                showChevron: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider().padding(.leading, 76)

                        NavigationLink(destination: PrivacySecurityPage()) {
                            UnifiedListRowV2(
                                iconName: "lock.shield.fill",
                                iconColor: .wiseForestGreen,
                                title: "Privacy & Security",
                                subtitle: "Control access and security settings",
                                value: "",
                                valueColor: .clear,
                                showChevron: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider().padding(.leading, 76)

                        NavigationLink(destination: AnalyticsInsightsPage().environmentObject(dataManager)) {
                            UnifiedListRowV2(
                                iconName: "chart.bar.fill",
                                iconColor: .wiseBrightGreen,
                                title: "Analytics & Insights",
                                subtitle: "View spending insights and trends",
                                value: "",
                                valueColor: .clear,
                                showChevron: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider().padding(.leading, 76)

                        NavigationLink(destination: HelpSupportPage()) {
                            UnifiedListRowV2(
                                iconName: "questionmark.circle.fill",
                                iconColor: .wiseOrange,
                                title: "Help & Support",
                                subtitle: "Get help using Swiff",
                                value: "",
                                valueColor: .clear,
                                showChevron: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Linked Accounts
                    profileSection(title: "LINKED ACCOUNTS") {
                        if viewModel.accounts.isEmpty {
                            Text("No accounts linked yet")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wiseSecondaryText)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 24)
                        } else {
                            ForEach(viewModel.accounts) { account in
                                UnifiedListRowV2(
                                    iconName: "creditcard.fill",
                                    iconColor: .wiseSecondaryText,
                                    title: account.name,
                                    subtitle: "•••• \(account.last4)",
                                    value: "",
                                    valueColor: .clear,
                                    showChevron: true,
                                    onTap: {
                                        HapticManager.shared.impact(.light)
                                        selectedAccount = account
                                        showAccountDetails = true
                                    }
                                )
                                Divider().padding(.leading, 76)
                            }
                        }
                        
                        Button(action: {
                            HapticManager.shared.impact(.light)
                            showAddAccount = true
                        }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4]))
                                    .foregroundColor(.wiseBlue.opacity(0.5))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.wiseBlue)
                                    )
                                
                                Text("Add New Account")
                                    .font(.spotifyBodyLarge)
                                    .foregroundColor(.wiseBlue)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Settings
                    profileSection(title: "SETTINGS") {
                        UnifiedListRowV2(
                            iconName: "shield.fill",
                            iconColor: .wisePurple,
                            title: "Security",
                            subtitle: viewModel.security["twoFactor"] == true ? "2FA enabled" : "Security settings",
                            value: "",
                            valueColor: .clear,
                            showChevron: true,
                            onTap: {
                                HapticManager.shared.impact(.light)
                                showSecurity = true
                            }
                        )
                        
                        Divider().padding(.leading, 76)
                        
                        UnifiedListRowV2(
                            iconName: "wallet.pass.fill",
                            iconColor: .wiseForestGreen,
                            title: "Payment Methods",
                            subtitle: "Manage payment options",
                            value: "",
                            valueColor: .clear,
                            showChevron: true,
                            onTap: {
                                HapticManager.shared.impact(.light)
                                showPaymentMethods = true
                            }
                        )
                        
                        Divider().padding(.leading, 76)
                        
                        UnifiedListRowV2(
                            iconName: "gearshape.fill",
                            iconColor: .wiseSecondaryText,
                            title: "App Settings",
                            subtitle: "General application settings",
                            value: "",
                            valueColor: .clear,
                            showChevron: true,
                            onTap: {
                                HapticManager.shared.impact(.light)
                                showAppSettings = true
                            }
                        )
                    }

                    // Sign Out
                    profileSection {
                        Button(action: {
                            HapticManager.shared.impact(.medium)
                            showSignOutAlert = true
                        }) {
                            HStack(spacing: 12) {
                                UnifiedIconCircle(icon: "rectangle.portrait.and.arrow.right", color: .wiseError)
                                
                                Text("Sign Out")
                                    .font(.spotifyBodyLarge)
                                    .foregroundColor(.wiseError)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Version
                    Text(appVersion)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                }
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

    // MARK: - Helper Views

    @ViewBuilder
    private func profileSection<Content: View>(
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.leading, 16)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
            .subtleShadow()
        }
        .padding(.horizontal, 16)
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
