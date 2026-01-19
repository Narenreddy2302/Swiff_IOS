//
//  ProfileView.swift
//  Swiff IOS
//
//  Redesigned profile screen - Flat edge-to-edge style matching Feed page
//

import Combine
import PhotosUI
import SwiftUI

// MARK: - Color Extensions (Reference Style Adaptation)
extension Color {
    static let profileCyan = Color(red: 0.133, green: 0.827, blue: 0.933) // #22d3ee
    static let profileGreen = Color(red: 0.290, green: 0.871, blue: 0.502) // #4ade80
    static let profilePurple = Color(red: 0.753, green: 0.518, blue: 0.988) // #c084fc
    static let profileAmber = Color(red: 0.984, green: 0.749, blue: 0.141) // #fbbf24
    static let profileSlate = Color(red: 0.580, green: 0.639, blue: 0.722) // #94a3b8
    static let profileDanger = Color(red: 0.937, green: 0.267, blue: 0.267) // #ef4444
    static let profileSuccess = Color(red: 0.133, green: 0.773, blue: 0.369) // #22c55e
}

// MARK: - Profile Supporting Types

struct ProfileCurrencyOption: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let symbol: String
}

// MARK: - View Model

class ProfileViewModel: ObservableObject {
    @Published var security: [String: Bool] = [
        "twoFactor": false,
        "biometric": false,
        "loginAlerts": true,
    ]
    @Published var appSettings: [String: Bool] = [
        "compactView": false,
        "hideBalances": false,
    ]

    private let securityKey = "SecuritySettings"
    private let appSettingsKey = "AppSettings"

    init() { loadSettings() }

    private func loadSettings() {
        let defaults = UserDefaults.standard
        if let secData = defaults.dictionary(forKey: securityKey) as? [String: Bool] { security = secData }
        if let appData = defaults.dictionary(forKey: appSettingsKey) as? [String: Bool] { appSettings = appData }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
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
    @State private var showAppSettings = false
    @State private var showSignOutAlert = false

    // App version
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Swiff v\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wiseBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header
                        ProfileHeaderReferenceView(
                            profile: profileManager.profile,
                            onEdit: { showChangePhoto = true }
                        )
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                        .padding(.horizontal, 20)

                        // Contact Information
                        ProfileSectionView(title: "CONTACT INFORMATION") {
                            VStack(spacing: 0) {
                                ProfileMenuItemView(
                                    icon: "envelope.fill",
                                    iconColor: .profileCyan,
                                    title: "Email",
                                    subtitle: profileManager.profile.email.isEmpty ? "Add email" : profileManager.profile.email,
                                    showVerified: !profileManager.profile.email.isEmpty,
                                    action: { showEditEmail = true }
                                )
                                
                                Divider().padding(.leading, 76)
                                
                                ProfileMenuItemView(
                                    icon: "phone.fill",
                                    iconColor: .profileCyan,
                                    title: "Phone",
                                    subtitle: profileManager.profile.phone.isEmpty ? "Add phone" : profileManager.profile.phone,
                                    showVerified: !profileManager.profile.phone.isEmpty,
                                    action: { showEditPhone = true }
                                )
                                
                                Divider().padding(.leading, 76)
                                
                                ProfileMenuItemView(
                                    icon: "pencil",
                                    iconColor: .profileSlate,
                                    title: "Edit Name",
                                    subtitle: profileManager.profile.name,
                                    action: { showEditName = true }
                                )
                            }
                        }
                        .padding(.bottom, 32)

                        // Appearance
                        ProfileSectionView(title: "APPEARANCE") {
                            ProfileThemeToggleView(
                                themeMode: $userSettings.themeMode
                            )
                        }
                        .padding(.bottom, 32)

                        // Settings
                        ProfileSectionView(title: "SETTINGS") {
                            VStack(spacing: 0) {
                                NavigationLink(destination: ProfileSettingsPage()) {
                                    ProfileMenuItemViewContent(
                                        icon: "person.fill",
                                        iconColor: .profileCyan,
                                        title: "Profile Settings",
                                        subtitle: "Profile, notifications & storage"
                                    )
                                }
                                .buttonStyle(ProfileMenuButtonStyle())

                                Divider().background(Color.wiseBorder).padding(.leading, 76)

                                NavigationLink(destination: PrivacySecurityPage()) {
                                    ProfileMenuItemViewContent(
                                        icon: "checkmark.shield.fill",
                                        iconColor: .profileGreen,
                                        title: "Privacy & Security",
                                        subtitle: "Control access and security settings"
                                    )
                                }
                                .buttonStyle(ProfileMenuButtonStyle())

                                Divider().background(Color.wiseBorder).padding(.leading, 76)

                                NavigationLink(destination: AnalyticsInsightsPage().environmentObject(dataManager)) {
                                    ProfileMenuItemViewContent(
                                        icon: "chart.bar.fill",
                                        iconColor: .profileAmber,
                                        title: "Analytics & Insights",
                                        subtitle: "View spending insights and trends"
                                    )
                                }
                                .buttonStyle(ProfileMenuButtonStyle())

                                Divider().background(Color.wiseBorder).padding(.leading, 76)
                                
                                NavigationLink(destination: HelpSupportPage()) {
                                    ProfileMenuItemViewContent(
                                        icon: "questionmark.circle.fill",
                                        iconColor: .profileAmber,
                                        title: "Help & Support",
                                        subtitle: "Get help using Swiff"
                                    )
                                }
                                .buttonStyle(ProfileMenuButtonStyle())

                                Divider().background(Color.wiseBorder).padding(.leading, 76)

                                Button(action: { showAppSettings = true }) {
                                    ProfileMenuItemViewContent(
                                        icon: "gearshape.fill",
                                        iconColor: .profileSlate,
                                        title: "App Settings",
                                        subtitle: "General application settings"
                                    )
                                }
                                .buttonStyle(ProfileMenuButtonStyle())
                            }
                        }
                        .padding(.bottom, 32)

                        // Sign Out
                        ProfileSignOutButtonView(action: {
                            showSignOutAlert = true
                        })
                        .padding(.bottom, 28)

                        // Footer
                        Text(appVersion)
                            .font(.system(size: 12))
                            .foregroundColor(.wiseTertiaryText)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.wisePrimaryText)
                }
            }
        }
        // MARK: - Sheets & Alerts (Preserved)
        .sheet(isPresented: $showEditName) {
            ProfileEditFieldSheet(title: "Edit Name", value: Binding(get: { profileManager.profile.name }, set: { var p = profileManager.profile; p.name = $0; profileManager.updateProfile(p) }), placeholder: "Enter name", keyboardType: .default)
        }
        .sheet(isPresented: $showEditEmail) {
            ProfileEditFieldSheet(title: "Edit Email", value: Binding(get: { profileManager.profile.email }, set: { var p = profileManager.profile; p.email = $0; profileManager.updateProfile(p) }), placeholder: "Enter email", keyboardType: .emailAddress)
        }
        .sheet(isPresented: $showEditPhone) {
            ProfileEditFieldSheet(title: "Edit Phone", value: Binding(get: { profileManager.profile.phone }, set: { var p = profileManager.profile; p.phone = $0; profileManager.updateProfile(p) }), placeholder: "Enter phone", keyboardType: .phonePad)
        }
        .sheet(isPresented: $showChangePhoto) {
            ProfileChangePhotoSheet(profileManager: profileManager)
        }
        .sheet(isPresented: $showAppSettings) {
            ProfileAppSettingsSheet(appSettings: $viewModel.appSettings, onSave: { viewModel.saveSettings() })
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                HapticManager.shared.notification(.success)
                toastManager.showInfo("Signed out successfully")
            }
        } message: {
            Text("Sign out of your account?")
        }
    }
}

// MARK: - Component Implementation (Flat List Style)

struct ProfileHeaderReferenceView: View {
    let profile: UserProfile
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Avatar
            Button(action: onEdit) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.122, green: 0.165, blue: 0.071),
                                    Color(red: 0.082, green: 0.102, blue: 0.051)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .stroke(Color.profileGreen.opacity(0.2), lineWidth: 2)
                        )
                    
                    AvatarView(avatarType: profile.avatarType, size: .xxlarge, style: .solid)
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 20)
            
            // Name
            Text(profile.name.isEmpty ? "Add Your Name" : profile.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.wisePrimaryText)
                .kerning(-0.5)
                .padding(.bottom, 6)
            
            // Email
            if !profile.email.isEmpty {
                Text(profile.email)
                    .font(.system(size: 14))
                    .foregroundColor(.wiseSecondaryText)
                    .padding(.bottom, 2)
            }
            
            // Phone
            if !profile.phone.isEmpty {
                Text(profile.phone)
                    .font(.system(size: 14))
                    .foregroundColor(.wiseTertiaryText)
                    .padding(.bottom, 4)
            }
            
            // Member Since
            Text("Member since \(profile.createdDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.system(size: 12))
                .foregroundColor(.wiseTertiaryText)
        }
    }
}

struct ProfileSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.wiseTertiaryText)
                .kerning(0.5)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            
            content
        }
    }
}

struct ProfileMenuItemView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var showVerified: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ProfileMenuItemViewContent(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: subtitle,
                showVerified: showVerified
            )
        }
        .buttonStyle(ProfileMenuButtonStyle())
    }
}

struct ProfileMenuItemViewContent: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var showVerified: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Right side
            HStack(spacing: 10) {
                if showVerified {
                    Text("Verified")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.profileSuccess)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.profileSuccess.opacity(0.12))
                        .cornerRadius(100)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.wiseTertiaryText.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .background(Color.wiseBackground)
    }
}

struct ProfileThemeToggleView: View {
    @Binding var themeMode: String

    private var isDarkMode: Binding<Bool> {
        Binding(
            get: { themeMode.lowercased() == "dark" },
            set: { isDark in
                let newMode = isDark ? "Dark" : "Light"
                if themeMode != newMode {
                    ThemeTransitionManager.shared.animateThemeChange {
                        themeMode = newMode
                    }
                }
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.profilePurple.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "moon.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.profilePurple)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text("Dark Mode")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                
                Text(isDarkMode.wrappedValue ? "On" : "Off")
                    .font(.system(size: 14))
                    .foregroundColor(.wiseSecondaryText)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: isDarkMode)
                .labelsHidden()
                .tint(.profilePurple)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.wiseBackground)
    }
}

// MARK: - Theme Transition Manager

class ThemeTransitionManager {
    static let shared = ThemeTransitionManager()
    private init() {}
    
    func animateThemeChange(duration: TimeInterval = 0.4, action: @escaping () -> Void) {
        guard let window = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: { $0.isKeyWindow }) else {
            action()
            return
        }
        
        guard let snapshot = window.snapshotView(afterScreenUpdates: false) else {
            action()
            return
        }
        
        snapshot.frame = window.bounds
        snapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(snapshot)
        
        action()
            
        UIView.animate(withDuration: duration, delay: 0.05, options: .curveEaseInOut) {
            snapshot.alpha = 0
        } completion: { _ in
            snapshot.removeFromSuperview()
        }
    }
}

struct ProfileSignOutButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.profileDanger.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 20))
                        .foregroundColor(.profileDanger)
                }
                
                Text("Sign Out")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.profileDanger)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .background(Color.wiseBackground)
        }
        .buttonStyle(ProfileSignOutButtonStyle())
    }
}

// MARK: - Button Styles

struct ProfileMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.wiseSecondaryText.opacity(0.05) : Color.clear)
    }
}

struct ProfileSignOutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.profileDanger.opacity(0.08) : Color.clear)
    }
}

// MARK: - Sheet Components

struct ProfileEditFieldSheet: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    @Environment(\.dismiss) private var dismiss
    @State private var tempValue = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(placeholder, text: $tempValue)
                    .keyboardType(keyboardType)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { value = tempValue; dismiss() } }
            }
        }
        .onAppear { tempValue = value }
    }
}

struct ProfileChangePhotoSheet: View {
    @ObservedObject var profileManager: UserProfileManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Select Photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity).padding().background(Color.wiseCardBackground).cornerRadius(10)
                }
                .padding()
                
                Button("Remove Photo", role: .destructive) {
                    var profile = profileManager.profile
                    profile.avatarType = .initials(profile.initials, colorIndex: 0)
                    profileManager.updateProfile(profile)
                    dismiss()
                }
            }
            .navigationTitle("Change Photo")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                if let item = newValue, let data = try? await item.loadTransferable(type: Data.self) {
                    var profile = profileManager.profile
                    profile.avatarType = .photo(data)
                    profileManager.updateProfile(profile)
                    dismiss()
                }
            }
        }
    }
}

struct ProfileAppSettingsSheet: View {
    @Binding var appSettings: [String: Bool]; let onSave: () -> Void; @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Compact View", isOn: Binding(get: { appSettings["compactView"] ?? false }, set: { appSettings["compactView"] = $0; onSave() }))
                Toggle("Hide Balances", isOn: Binding(get: { appSettings["hideBalances"] ?? false }, set: { appSettings["hideBalances"] = $0; onSave() }))
            }
            .navigationTitle("App Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}