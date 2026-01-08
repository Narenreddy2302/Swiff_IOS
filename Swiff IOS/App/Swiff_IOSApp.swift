//
//  Swiff_IOSApp.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/11/25.
//  Updated on 11/18/25 to use SwiftData and DataManager
//  Updated on 11/21/25 to add widget deep link support
//  Updated by Agent 12 on 11/21/25 to add Spotlight search integration
//  Updated on 01/07/26 to add Supabase integration
//  Updated on 01/07/26 to add authentication flow
//

import Combine
import CoreSpotlight
import SwiftData
import SwiftUI
import WidgetKit

@main
struct Swiff_IOSApp: App {
    // Use PersistenceService's ModelContainer (single source of truth)
    // This is initialized synchronously before app launch
    @MainActor
    var sharedModelContainer: ModelContainer {
        return PersistenceService.shared.modelContainer
    }

    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(
        forKey: "hasCompletedOnboarding")

    // Deep Link Handler for widget interactions
    @StateObject private var deepLinkHandler = DeepLinkHandler()

    // Spotlight search result navigation
    @StateObject private var spotlightNavigation = SpotlightNavigationHandler()

    // Supabase services
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var syncService = SyncService.shared

    var body: some Scene {
        WindowGroup {
            SwiftUI.Group {
                // Check authentication state first
                if authService.isCheckingAuth {
                    // Show loading screen while checking auth
                    AuthLoadingView()
                        .environmentObject(authService)
                } else if !authService.isAuthenticated {
                    // User not authenticated - show login/signup
                    AuthenticationView()
                        .environmentObject(authService)
                } else if !authService.isEmailVerified {
                    // User authenticated but email not verified
                    EmailVerificationPendingView(
                        email: authService.currentUserEmail ?? "",
                        onBackToLogin: {
                            Task {
                                try? await authService.signOut()
                            }
                        },
                        onUseDifferentEmail: {
                            Task {
                                try? await authService.signOut()
                            }
                        },
                        onVerified: {
                            // Refresh verification status
                            Task {
                                _ = await authService.checkEmailVerification()
                            }
                        }
                    )
                    .environmentObject(authService)
                } else if showOnboarding {
                    // User authenticated and verified - show onboarding
                    OnboardingView {
                        withAnimation(.smooth) {
                            showOnboarding = false
                        }
                    }
                    .environmentObject(deepLinkHandler)
                    .environmentObject(authService)
                } else {
                    // User fully authenticated, verified, and onboarded - show main app
                    ContentView()
                        .environmentObject(DataManager.shared)
                        .environmentObject(deepLinkHandler)
                        .environmentObject(spotlightNavigation)
                        .environmentObject(authService)
                        .environmentObject(syncService)
                        .onAppear {
                            // Load all persisted data on app launch
                            DataManager.shared.loadAllData()

                            // Sync device contacts (if permission granted)
                            Task {
                                await DataManager.shared.syncContacts()
                            }

                            // Create automatic backup if needed (every 7 days)
                            BackupService.shared.createAutomaticBackupIfNeeded()

                            // Update widget data
                            updateWidgetData()

                            // Enable Spotlight indexing
                            DataManager.shared.enableSpotlightIndexing()

                            // Initialize Supabase sync if user is authenticated
                            initializeSupabaseSync()
                        }
                        .onOpenURL { url in
                            // Handle deep links from widgets
                            deepLinkHandler.handle(url: url)
                        }
                        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                            // Handle Spotlight search results
                            handleSpotlightResult(userActivity)
                        }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Widget Data Management

    /// Update widget data when app becomes active
    private func updateWidgetData() {
        Task {
            await refreshWidgetData()
        }
    }

    @MainActor
    private func refreshWidgetData() async {
        // MOCK: In production, this would fetch real data from DataManager
        // For now, we'll use mock data from WidgetDataService

        print("📱 Refreshing widget data from main app...")

        // Example: Update upcoming renewals
        // let subscriptions = DataManager.shared.subscriptions
        // let widgetSubscriptions = subscriptions.map { WidgetSubscription(from: $0) }
        // WidgetDataService.shared.saveUpcomingRenewals(widgetSubscriptions)

        // Example: Update monthly spending
        // let spending = calculateMonthlySpending()
        // WidgetDataService.shared.saveMonthlySpending(spending)

        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()

        print("✅ Widget data refreshed")
    }

    // MARK: - Supabase Sync Initialization

    /// Initialize Supabase sync if user is authenticated
    private func initializeSupabaseSync() {
        Task {
            await setupSupabaseSync()
        }
    }

    @MainActor
    private func setupSupabaseSync() async {
        // Check if user is authenticated
        guard SupabaseService.shared.currentUser != nil else {
            print("📱 No authenticated user, skipping Supabase sync")
            return
        }

        print("📱 Initializing Supabase sync...")

        do {
            // Get the model context from the shared container
            let modelContext = ModelContext(sharedModelContainer)

            // Check for pending changes that need to be synced
            if syncService.pendingChangesCount > 0 {
                print("📤 Syncing \(syncService.pendingChangesCount) pending changes...")
                await syncService.syncPendingChanges()
            }

            // Start realtime sync for live updates
            await syncService.startRealtimeSync(modelContext: modelContext)

            // Perform incremental sync to get any changes from server
            try await syncService.performIncrementalSync(modelContext: modelContext)

            print("✅ Supabase sync initialized successfully")
        } catch {
            print("⚠️ Supabase sync initialization failed: \(error.localizedDescription)")
            // Continue with local data - offline-first approach
        }
    }

    // MARK: - Spotlight Search Result Handling

    /// Handle Spotlight search result and navigate to the appropriate view
    private func handleSpotlightResult(_ userActivity: NSUserActivity) {
        guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
        else {
            print("⚠️ No identifier found in Spotlight user activity")
            return
        }

        print("🔍 Handling Spotlight result: \(identifier)")

        // Parse the identifier to get entity type and ID
        guard let navigation = SpotlightResultNavigation(from: identifier) else {
            print("⚠️ Failed to parse Spotlight identifier: \(identifier)")
            return
        }

        // Navigate based on entity type
        spotlightNavigation.navigateToEntity(type: navigation.entityType, id: navigation.entityId)

        print("✅ Navigating to \(navigation.entityType.rawValue) with ID: \(navigation.entityId)")
    }
}

// MARK: - Spotlight Navigation Handler

/// Observable object to handle navigation from Spotlight search results
@MainActor
class SpotlightNavigationHandler: ObservableObject {
    @Published var selectedPersonId: UUID?
    @Published var selectedSubscriptionId: UUID?
    @Published var selectedTransactionId: UUID?
    @Published var shouldNavigateToTab: Int?

    func navigateToEntity(type: SpotlightResultNavigation.EntityType, id: UUID) {
        // Reset all selections
        selectedPersonId = nil
        selectedSubscriptionId = nil
        selectedTransactionId = nil
        shouldNavigateToTab = nil

        // Set the appropriate selection based on type
        // Tab order: Home(0) - People(1) - +(2) - Subscriptions(3) - Feed(4)
        switch type {
        case .person:
            selectedPersonId = id
            shouldNavigateToTab = 1  // People tab
        case .subscription:
            selectedSubscriptionId = id
            shouldNavigateToTab = 3  // Subscriptions tab
        case .transaction:
            selectedTransactionId = id
            shouldNavigateToTab = 0  // Home/Transactions tab
        }
    }

    func clearSelection() {
        selectedPersonId = nil
        selectedSubscriptionId = nil
        selectedTransactionId = nil
        shouldNavigateToTab = nil
    }
}
