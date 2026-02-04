//
//  MainTabView.swift
//  Swiff IOS
//
//  Created by Swiff AI on 11/18/25.
//  Refactored from ContentView.swift
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dataManager: DataManager

    // State
    @StateObject private var spotlightNavigation = SpotlightNavigationHandler()
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedTab: Int = 0
    @State private var showingAddTransaction = false

    // Computed props
    private var preferredColorSchemeValue: ColorScheme? {
        switch userSettings.themeMode.lowercased() {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    public init() {
        TabBarAccessor.setupAppearance()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Home
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label {
                        tabLabel("Home", tag: 0)
                    } icon: {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                            .environment(\.symbolVariants, .none)
                            .imageScale(.medium)
                    }
                }
                .tag(0)

            // Tab 1: People
            PeopleView()
                .tabItem {
                    Label {
                        tabLabel("People", tag: 1)
                    } icon: {
                        Image(systemName: selectedTab == 1 ? "person.2.fill" : "person.2")
                            .environment(\.symbolVariants, .none)
                            .imageScale(.medium)
                    }
                }
                .tag(1)

            // Tab 2: Add Button
            Color.clear
                .tabItem {
                    Label {
                        tabLabel("Add", tag: 2)
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                            .environment(\.symbolVariants, .none)
                            .imageScale(.large)
                    }
                }
                .tag(2)

            // Tab 3: Subscriptions
            SubscriptionsView()
                .tabItem {
                    Label {
                        tabLabel("Subscriptions", tag: 3)
                    } icon: {
                        Image(systemName: selectedTab == 3 ? "creditcard.fill" : "creditcard")
                            .environment(\.symbolVariants, .none)
                            .imageScale(.medium)
                    }
                }
                .tag(3)

            // Tab 4: Twitter-style Feed
            TwitterFeedView()
                .tabItem {
                    Label {
                        tabLabel("Feed", tag: 4)
                    } icon: {
                        Image(
                            systemName: selectedTab == 4 ? "square.stack.fill" : "square.stack"
                        )
                        .environment(\.symbolVariants, .none)
                        .imageScale(.medium)
                    }
                }
                .tag(4)
        }
        .tint(Theme.Colors.brandPrimary)  // Uses GREEN 5 (#043F2E)
        .preferredColorScheme(preferredColorSchemeValue)
        .dataManagerOverlays()  // Keep existing modifiers
        .toast()
        .onChange(of: selectedTab) { oldValue, newValue in
            handleTabChange(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: spotlightNavigation.shouldNavigateToTab) { oldValue, newValue in
            if let tab = newValue {
                selectedTab = tab
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionSheet(
                showingAddTransactionSheet: $showingAddTransaction,
                onTransactionAdded: { transaction in
                    handleTransactionAdded(transaction)
                }
            )
            .environmentObject(dataManager)
        }
    }

    // MARK: - Helper Functions

    private func handleTabChange(oldValue: Int, newValue: Int) {
        // Only trigger haptic for actual user navigation, not auto-reset from + button
        if newValue == 2 {
            HapticManager.shared.selection()
            showingAddTransaction = true
            // Reset to previous tab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedTab = oldValue
            }
        } else if oldValue != 2 {
            // Normal tab navigation (exclude the auto-reset case where oldValue is 2)
            HapticManager.shared.selection()
        }
    }

    private func handleTransactionAdded(_ transaction: Transaction) {
        do {
            try dataManager.addTransaction(transaction)
            HapticManager.shared.success()
        } catch {
            dataManager.error = error
        }
    }

    @ViewBuilder
    private func tabLabel(_ title: String, tag: Int) -> some View {
        switch userSettings.tabBarStyle {
        case "iconsOnly":
            Text("")
        case "selectedOnly":
            if selectedTab == tag {
                Text(title)
            } else {
                Text("")
            }
        default:  // "labels"
            Text(title)
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(DataManager.shared)  // Assuming shared instance exists or mocking it
}
