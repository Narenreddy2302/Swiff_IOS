//
//  AdvancedSettingsSection.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Advanced settings including defaults, formats, and developer options
//

import SwiftUI
import Combine

struct AdvancedSettingsSection: View {
    @StateObject private var userSettings = UserSettings.shared
    @State private var showingDeveloperOptions = false

    let billingCycles = ["Weekly", "Monthly", "Quarterly", "Annually"]
    let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "INR"]
    let weekDays = ["Sunday", "Monday"]
    let dateFormats = ["MM/DD/YYYY", "DD/MM/YYYY", "YYYY-MM-DD"]

    var body: some View {
        Section {
            // Default billing cycle
            Picker("Default Billing Cycle", selection: $userSettings.defaultBillingCycle) {
                ForEach(billingCycles, id: \.self) { cycle in
                    Text(cycle).tag(cycle)
                }
            }
            .font(.spotifyBodyMedium)
            .foregroundColor(.wisePrimaryText)

            // Default currency
            Picker("Default Currency", selection: $userSettings.defaultCurrency) {
                ForEach(currencies, id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }
            .font(.spotifyBodyMedium)
            .foregroundColor(.wisePrimaryText)

            // First day of week
            Picker("First Day of Week", selection: $userSettings.firstDayOfWeek) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    Text(day).tag(index)
                }
            }
            .font(.spotifyBodyMedium)
            .foregroundColor(.wisePrimaryText)

            // Date format
            Picker("Date Format", selection: $userSettings.dateFormat) {
                ForEach(dateFormats, id: \.self) { format in
                    Text(format).tag(format)
                }
            }
            .font(.spotifyBodyMedium)
            .foregroundColor(.wisePrimaryText)

            // Auto-categorization
            Toggle(isOn: $userSettings.autoCategorization) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transaction Auto-Categorization")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Automatically suggest categories for new transactions")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)

            // Developer options button (if enabled)
            if userSettings.developerOptionsEnabled {
                NavigationLink(destination: DeveloperOptionsView()) {
                    HStack {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(.wiseError)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Developer Options")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                            Text("Advanced debugging and testing tools")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                        Spacer()
                    }
                }
            }

        } header: {
            Text("Advanced")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        } footer: {
            Text("These settings control default values and behaviors for new items")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
    }
}

// Developer options view
struct DeveloperOptionsView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var userSettings = UserSettings.shared
    @State private var showingResetConfirmation = false
    @State private var showingClearDataConfirmation = false
    @State private var showingResetOnboardingConfirmation = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: .constant(true)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Debug Logs Enabled")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Log detailed information to console")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .tint(.wiseForestGreen)
                .disabled(true) // Always enabled in dev mode

                Button(action: {
                    // Simulate a test crash (optional)
                    print("Test crash reporting triggered")
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.wiseError)
                        Text("Test Crash Reporting")
                            .foregroundColor(.wisePrimaryText)
                        Spacer()
                    }
                }

            } header: {
                Text("Debugging")
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
            }

            Section {
                Button(action: {
                    showingClearDataConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.wiseError)
                        Text("Clear All Data (No Confirmation)")
                            .foregroundColor(.wiseError)
                        Spacer()
                    }
                }

                Button(action: {
                    showingResetOnboardingConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.wiseBlue)
                        Text("Reset Onboarding")
                            .foregroundColor(.wisePrimaryText)
                        Spacer()
                    }
                }

                Button(action: {
                    showingResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundColor(.wiseBlue)
                        Text("Reset All Settings")
                            .foregroundColor(.wisePrimaryText)
                        Spacer()
                    }
                }

            } header: {
                Text("Reset Actions")
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
            } footer: {
                Text("⚠️ Warning: These actions cannot be undone. Use with caution.")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseError)
            }

            Section {
                HStack {
                    Text("App Version")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(.wiseSecondaryText)
                }

                HStack {
                    Text("Build Number")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundColor(.wiseSecondaryText)
                }

                HStack {
                    Text("Environment")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Text("Development")
                        .foregroundColor(.wiseError)
                }

            } header: {
                Text("Build Info")
                    .font(.spotifyLabelSmall)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .navigationTitle("Developer Options")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear All Data?", isPresented: $showingClearDataConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                do {
                    try dataManager.clearAllData()
                    ToastManager.shared.showSuccess("All data cleared")
                } catch {
                    ToastManager.shared.showError("Failed to clear data: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("This will permanently delete all your data. This action cannot be undone.")
        }
        .alert("Reset Onboarding?", isPresented: $showingResetOnboardingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                ToastManager.shared.showSuccess("Onboarding reset. Restart the app to see onboarding again.")
            }
        } message: {
            Text("This will reset the onboarding flow. You'll see it again on next launch.")
        }
        .alert("Reset All Settings?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                userSettings.resetToDefaults()
                ToastManager.shared.showSuccess("All settings reset to defaults")
            }
        } message: {
            Text("This will reset all your preferences to their default values.")
        }
    }
}

#Preview("Advanced Settings Section") {
    NavigationView {
        List {
            AdvancedSettingsSection()
        }
        .environmentObject(DataManager.shared)
    }
}
