//
//  HomeView.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Refactored from ContentView.swift
//

import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @Binding var selectedTab: Int
    @State private var showingSettings = false
    @State private var showingProfile = false
    @State private var showingSearch = false
    @State private var showingQuickActions = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background that extends to all edges
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Top Header with Profile and Actions
                        TopHeaderSection(
                            showingSettings: $showingSettings,
                            showingProfile: $showingProfile,
                            showingSearch: $showingSearch,
                            showingQuickActions: $showingQuickActions
                        )

                        // Main Content Section
                        VStack(spacing: 20) {
                            // Today Section (moved down)
                            TodaySection()

                            // Four Card Grid
                            FinancialOverviewGrid(selectedTab: $selectedTab)

                            // Recent Transactions Section
                            RecentActivitySection()

                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                }
                .navigationBarHidden(true)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingSearch) {
            SearchView()
        }
        .sheet(isPresented: $showingQuickActions) {
            QuickActionSheet()
        }
    }
}

// MARK: - Top Header Section
struct TopHeaderSection: View {
    @Binding var showingSettings: Bool
    @Binding var showingProfile: Bool
    @Binding var showingSearch: Bool
    @Binding var showingQuickActions: Bool

    @StateObject private var profileManager = UserProfileManager.shared

    var body: some View {
        HStack {
            // Profile Avatar (left corner)
            Button(action: {
                HapticManager.shared.impact(.medium)
                showingProfile = true
            }) {
                AvatarView(
                    avatarType: profileManager.profile.avatarType,
                    size: .medium,
                    style: .solid
                )
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
            .accessibilityLabel("Profile")
            .accessibilityHint("Double tap to open your profile")

            Spacer()

            // Logo in center
            Text("Swiff.")
                .font(Theme.Fonts.displayMedium)
                .foregroundColor(Theme.Colors.brandPrimary)

            Spacer()

            // Add Button (right corner)
            HeaderActionButton(icon: "plus.circle.fill", color: Theme.Colors.brandPrimary) {
                HapticManager.shared.impact(.medium)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showingQuickActions = true
                }
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
                    .font(Theme.Fonts.displayLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()
            }

            HStack {
                Text(Date().formatted(.dateTime.weekday(.abbreviated).day().month(.wide)))
                    .font(Theme.Fonts.bodyLarge)
                    .foregroundColor(Theme.Colors.textSecondary)

                Spacer()
            }
        }
    }
}
