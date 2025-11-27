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
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Sheet State Variables

    @State private var showingEditProfile = false
    @State private var showingAnalytics = false
    @State private var showingSettings = false
    @State private var showingHelp = false

    // MARK: - App Version String

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (Build \(build))"
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // HEADER WITH TITLE
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
                        // PROFILE HEADER CARD
                        HStack(spacing: 16) {
                            // Profile Avatar
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
                        }
                        .padding(16)
                        .background(Color.wiseCardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.wiseShadowColor, radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // MENU OPTIONS
                        VStack(spacing: 0) {
                            // General
                            MenuOptionRow(
                                icon: "person.circle",
                                title: "General",
                                subtitle: "Profile, notifications & storage",
                                iconColor: .wisePrimaryText,
                                action: {
                                    HapticManager.shared.impact(.medium)
                                    showingEditProfile = true
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 72)
                            
                            // Security
                            MenuOptionRow(
                                icon: "lock.shield",
                                title: "Security",
                                subtitle: "Control how you access Pleo & your card",
                                iconColor: .wisePrimaryText,
                                action: {
                                    HapticManager.shared.impact(.medium)
                                    showingSettings = true
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 72)
                            
                            // Power ups
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
                            
                            // Chat with Pleo
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
                        
                        // APP VERSION
                        Text(appVersion)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText.opacity(0.6))
                            .padding(.top, 32)
                            .padding(.bottom, 100)
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
        }
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
}

// MARK: - Menu Option Row

struct MenuOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon container
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
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wiseSecondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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
    let dataManager = DataManager.shared
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
