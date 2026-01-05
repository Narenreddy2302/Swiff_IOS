//
//  ProfileView.swift
//  Swiff
//
//  Created for Swiff Banking App
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    static let bgPrimary = Color.black
    static let bgCard = Color(red: 0.067, green: 0.067, blue: 0.067) // #111111
    static let bgHover = Color(red: 0.1, green: 0.1, blue: 0.1) // #1a1a1a
    static let accent = Color(red: 0.639, green: 0.902, blue: 0.208) // #a3e635
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.667) // #a1a1aa
    static let textMuted = Color(red: 0.443, green: 0.443, blue: 0.478) // #71717a
    static let borderColor = Color.white.opacity(0.06)
    static let successColor = Color(red: 0.133, green: 0.773, blue: 0.369) // #22c55e
    static let dangerColor = Color(red: 0.937, green: 0.267, blue: 0.267) // #ef4444
    static let cyanColor = Color(red: 0.133, green: 0.827, blue: 0.933) // #22d3ee
    static let greenColor = Color(red: 0.290, green: 0.871, blue: 0.502) // #4ade80
    static let purpleColor = Color(red: 0.753, green: 0.518, blue: 0.988) // #c084fc
    static let amberColor = Color(red: 0.984, green: 0.749, blue: 0.141) // #fbbf24
    static let slateColor = Color(red: 0.580, green: 0.639, blue: 0.722) // #94a3b8
}

// MARK: - Main Profile View
struct ProfileView: View {
    @State private var showingSignOutAlert = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        ZStack {
            Color.bgPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Section
                    ProfileHeaderView()
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    
                    // Contact Information
                    SectionView(title: "CONTACT INFORMATION") {
                        VStack(spacing: 0) {
                            MenuItemView(
                                icon: "envelope.fill",
                                iconColor: .cyanColor,
                                title: "Email",
                                subtitle: "agulanarenreddy@gmail.com",
                                showVerified: true,
                                action: { showToastMessage("Opening Email") }
                            )
                            
                            Divider()
                                .background(Color.borderColor)
                            
                            MenuItemView(
                                icon: "phone.fill",
                                iconColor: .cyanColor,
                                title: "Phone",
                                subtitle: "2038045070",
                                showVerified: true,
                                action: { showToastMessage("Opening Phone") }
                            )
                        }
                    }
                    .padding(.bottom, 28)
                    
                    // Appearance
                    SectionView(title: "APPEARANCE") {
                        ThemeMenuItemView(
                            action: { showToastMessage("Theme options") }
                        )
                    }
                    .padding(.bottom, 28)
                    
                    // Settings
                    SectionView(title: "SETTINGS") {
                        VStack(spacing: 0) {
                            MenuItemView(
                                icon: "person.fill",
                                iconColor: .cyanColor,
                                title: "Profile Settings",
                                subtitle: "Profile, notifications & storage",
                                action: { showToastMessage("Opening Profile Settings") }
                            )
                            
                            Divider()
                                .background(Color.borderColor)
                            
                            MenuItemView(
                                icon: "checkmark.shield.fill",
                                iconColor: .greenColor,
                                title: "Privacy & Security",
                                subtitle: "Control access and security settings",
                                action: { showToastMessage("Opening Privacy & Security") }
                            )
                            
                            Divider()
                                .background(Color.borderColor)
                            
                            MenuItemView(
                                icon: "questionmark.circle.fill",
                                iconColor: .amberColor,
                                title: "Help & Support",
                                subtitle: "Get help using Swiff",
                                action: { showToastMessage("Opening Help & Support") }
                            )
                            
                            Divider()
                                .background(Color.borderColor)
                            
                            MenuItemView(
                                icon: "gearshape.fill",
                                iconColor: .slateColor,
                                title: "App Settings",
                                subtitle: "General application settings",
                                action: { showToastMessage("Opening App Settings") }
                            )
                        }
                    }
                    .padding(.bottom, 28)
                    
                    // Sign Out
                    SignOutButtonView(action: {
                        showingSignOutAlert = true
                    })
                    .padding(.bottom, 28)
                    
                    // Footer
                    Text("Swiff v1.0.0")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            
            // Toast
            if showToast {
                VStack {
                    Spacer()
                    ToastView(message: toastMessage)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showToast)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showToastMessage("Going back") }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.textPrimary)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.textPrimary)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                showToastMessage("Signing out...")
            }
        } message: {
            Text("Sign out of your account?")
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Avatar
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
                            .stroke(Color.accent.opacity(0.2), lineWidth: 2)
                    )
                
                Text("😍")
                    .font(.system(size: 40))
            }
            .padding(.bottom, 20)
            
            // Name
            Text("Naren")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
                .kerning(-0.5)
                .padding(.bottom, 6)
            
            // Email
            Text("agulanarenreddy@gmail.com")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .padding(.bottom, 2)
            
            // Phone
            Text("2038045070")
                .font(.system(size: 14))
                .foregroundColor(.textMuted)
                .padding(.bottom, 4)
            
            // Member Since
            Text("Member since Nov 26, 2025")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
        }
    }
}

// MARK: - Section View
struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textMuted)
                .kerning(0.8)
                .padding(.leading, 2)
            
            content
                .background(Color.bgCard)
                .cornerRadius(16)
        }
    }
}

// MARK: - Menu Item View
struct MenuItemView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var showVerified: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right side
                HStack(spacing: 10) {
                    if showVerified {
                        Text("Verified")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.successColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.successColor.opacity(0.12))
                            .cornerRadius(100)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textMuted.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuButtonStyle())
    }
}

// MARK: - Theme Menu Item View
struct ThemeMenuItemView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purpleColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.purpleColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 1) {
                    Text("App Theme")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textPrimary)
                    
                    Text("Dark")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                }
                
                Spacer()
                
                // Theme toggle
                HStack(spacing: 6) {
                    Text("Dark")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuButtonStyle())
    }
}

// MARK: - Sign Out Button View
struct SignOutButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.dangerColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18))
                        .foregroundColor(.dangerColor)
                }
                
                Text("Sign Out")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.dangerColor)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(SignOutButtonStyle())
        .background(Color.bgCard)
        .cornerRadius(16)
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.successColor)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.bgCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderColor, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Button Styles
struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.bgHover : Color.clear)
    }
}

struct SignOutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.dangerColor.opacity(0.08) : Color.clear)
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - App Entry Point (for standalone testing)
@main
struct SwiffApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ProfileView()
            }
            .preferredColorScheme(.dark)
        }
    }
}
