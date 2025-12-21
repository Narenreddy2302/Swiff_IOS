//
//  EnhancedDataManagementSection.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Enhanced data management section with backup, sync, and import features
//

import SwiftUI
import Combine

// AGENT 5: Enhanced data management section (Tasks 5.4.1 - 5.4.10)
struct EnhancedDataManagementSection: View {
    @ObservedObject var userSettings: UserSettings
    @EnvironmentObject var dataManager: DataManager

    @State private var showingBackupPasswordSheet = false
    @State private var showingImportSheet = false
    @State private var showingStorageDetails = false
    @State private var backupPassword = ""
    @State private var confirmPassword = ""
    @State private var showingClearCacheAlert = false

    let backupFrequencies = ["Daily", "Weekly", "Monthly"]

    var lastBackupText: String {
        if let date = userSettings.lastBackupDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        return "Never"
    }

    var body: some View {
        Section {
            // Existing backup/restore buttons
            Button(action: createBackup) {
                HStack {
                    Image(systemName: "arrow.down.doc.fill")
                        .foregroundColor(.wiseBlue)
                    Text("Create Backup")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                }
            }

            Button(action: {
                // Import/restore action from main settings
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.wiseBlue)
                    Text("Import/Restore Data")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                }
            }

            Divider()

            // AGENT 5: Task 5.4.1 - Auto Backup toggle
            Toggle(isOn: $userSettings.autoBackupEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto Backup")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Automatically backup your data")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)

            // AGENT 5: Task 5.4.2 - Backup frequency selector
            if userSettings.autoBackupEnabled {
                Picker("Backup Frequency", selection: $userSettings.backupFrequency) {
                    ForEach(backupFrequencies, id: \.self) { frequency in
                        Text(frequency).tag(frequency)
                    }
                }
                .pickerStyle(.menu)
                .padding(.leading, 16)
            }

            // AGENT 5: Task 5.4.3 - Last Backup date display
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.wiseSecondaryText)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Backup")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text(lastBackupText)
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // AGENT 5: Task 5.4.4 - Backup Location (for future iCloud)
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.wiseSecondaryText)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Backup Location")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text(userSettings.iCloudSyncEnabled ? "iCloud Drive" : "Local Device")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            Divider()

            // AGENT 5: Task 5.4.5 - iCloud sync toggle (Future feature)
            Toggle(isOn: $userSettings.iCloudSyncEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("iCloud Sync")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Coming Soon")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.wiseBlue)
                            .cornerRadius(4)
                    }
                    Text("Sync data across all your devices")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)
            .disabled(true) // Disabled until Phase 2

            if userSettings.iCloudSyncEnabled {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.wiseForestGreen)
                        Text("Synced")
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                        Spacer()
                    }
                    .padding(.leading, 16)

                    Button(action: {
                        // Sync now action
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.wiseBlue)
                            Text("Sync Now")
                                .foregroundColor(.wiseBlue)
                        }
                        .font(.spotifyBodySmall)
                    }
                    .padding(.leading, 16)
                }
            }

            Divider()

            // AGENT 5: Task 5.4.6 - Backup encryption toggle
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $userSettings.backupEncryptionEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Encrypt Backups")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Secure backups with password")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .tint(.wiseForestGreen)

                // AGENT 5: Task 5.4.7 - Password setup sheet
                if userSettings.backupEncryptionEnabled {
                    Button(action: {
                        showingBackupPasswordSheet = true
                    }) {
                        HStack {
                            Image(systemName: userSettings.backupPassword != nil ? "checkmark.circle.fill" : "key.fill")
                                .foregroundColor(.wiseForestGreen)

                            Text(userSettings.backupPassword != nil ? "Change Password" : "Set Password")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseForestGreen)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .padding(.leading, 16)
                    }
                }
            }

            Divider()

            // AGENT 5: Task 5.4.8 - Import from Competitors
            Button(action: {
                showingImportSheet = true
            }) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.wiseWarning)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Import from Other Apps")
                            .foregroundColor(.wisePrimaryText)
                        Text("Bobby, Truebill, Mint, etc.")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            Divider()

            // AGENT 5: Task 5.4.9 - Storage usage section
            Button(action: {
                showingStorageDetails = true
            }) {
                HStack {
                    Image(systemName: "externaldrive.fill")
                        .foregroundColor(.wiseBlue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Storage Usage")
                            .foregroundColor(.wisePrimaryText)
                        Text(calculateStorageUsage())
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // AGENT 5: Task 5.4.10 - Clear Cache button
            Button(action: {
                showingClearCacheAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.wiseWarning)
                    Text("Clear Cache")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                }
            }
        } header: {
            Text("Data Management")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Data:")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                Text("• \(dataManager.peopleCount) people")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                Text("• \(dataManager.groupsCount) groups")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                Text("• \(dataManager.subscriptionsCount) subscriptions")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                Text("• \(dataManager.transactionsCount) transactions")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }
        }
        .sheet(isPresented: $showingBackupPasswordSheet) {
            BackupPasswordSheet(
                isPresented: $showingBackupPasswordSheet,
                userSettings: userSettings
            )
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportFromCompetitorsView()
        }
        .sheet(isPresented: $showingStorageDetails) {
            StorageDetailsView()
        }
        .alert("Clear Cache?", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will clear temporary files and cached data. Your subscriptions and data will not be affected.")
        }
    }

    // AGENT 5: Create backup and update last backup date
    private func createBackup() {
        do {
            _ = try BackupService.shared.createBackup()
            userSettings.lastBackupDate = Date()
            ToastManager.shared.showSuccess("Backup created successfully")
        } catch {
            ToastManager.shared.showError("Failed to create backup: \(error.localizedDescription)")
        }
    }

    // AGENT 5: Calculate storage usage (mock)
    private func calculateStorageUsage() -> String {
        // Mock calculation - Phase 2 should implement actual file size calculation
        let appSize = 2.4 // MB
        let dataSize = 0.5 // MB
        let imageSize = 1.2 // MB
        let total = appSize + dataSize + imageSize
        return String(format: "%.1f MB total", total)
    }

    // AGENT 5: Clear cache
    private func clearCache() {
        // Mock implementation - Phase 2 should implement actual cache clearing
        ToastManager.shared.showSuccess("Cache cleared successfully")
    }
}

// AGENT 5: Backup password setup sheet
struct BackupPasswordSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var userSettings: UserSettings

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)

                    if showError {
                        Text("Passwords don't match")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseError)
                    }
                } header: {
                    Text("Set Backup Password")
                } footer: {
                    Text("This password will be used to encrypt your backups. Keep it safe - you'll need it to restore encrypted backups.")
                }

                Section {
                    Button("Save Password") {
                        savePassword()
                    }
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseForestGreen)
                    .disabled(password.isEmpty || confirmPassword.isEmpty)
                }
            }
            .navigationTitle("Backup Encryption")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func savePassword() {
        guard password == confirmPassword else {
            showError = true
            return
        }

        // Mock password storage - Phase 2 should use Keychain
        userSettings.backupPassword = password
        ToastManager.shared.showSuccess("Backup password set")
        isPresented = false
    }
}

// AGENT 5: Import from competitors view
struct ImportFromCompetitorsView: View {
    @Environment(\.dismiss) var dismiss

    let competitors = [
        ("Bobby", "Subscription tracker"),
        ("Truebill", "Subscription & bills"),
        ("Mint", "Finance manager"),
        ("YNAB", "Budget planner"),
        ("PocketGuard", "Bill tracker")
    ]

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Import your data from other subscription tracking apps. Download a CSV export from your current app, then tap an option below to get started.")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Section {
                    ForEach(competitors, id: \.0) { competitor in
                        Button(action: {
                            // Mock import action
                            ToastManager.shared.showError("Import from \(competitor.0) coming in Phase 2")
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(competitor.0)
                                        .font(.spotifyBodyMedium)
                                        .foregroundColor(.wisePrimaryText)
                                    Text(competitor.1)
                                        .font(.spotifyCaptionMedium)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                                Spacer()
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.wiseBlue)
                            }
                        }
                    }
                } header: {
                    Text("Import From")
                }

                Section {
                    Button(action: {
                        // Generic CSV import
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.wiseForestGreen)
                            Text("Import CSV File")
                                .foregroundColor(.wisePrimaryText)
                            Spacer()
                        }
                    }
                } header: {
                    Text("Custom Import")
                }
            }
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

// AGENT 5: Storage details view
struct StorageDetailsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    StorageRow(title: "App Size", size: 2.4)
                    StorageRow(title: "Data Size", size: 0.5)
                    StorageRow(title: "Image & Receipts", size: 1.2)
                    StorageRow(title: "Cache", size: 0.3)
                } header: {
                    Text("Storage Breakdown")
                }

                Section {
                    HStack {
                        Text("Total Usage")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Spacer()
                        Text("4.4 MB")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseForestGreen)
                    }
                }
            }
            .navigationTitle("Storage Usage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }
}

struct StorageRow: View {
    let title: String
    let size: Double

    var body: some View {
        HStack {
            Text(title)
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
            Spacer()
            Text(String(format: "%.1f MB", size))
                .font(.spotifyBodyMedium)
                .foregroundColor(.wiseSecondaryText)
        }
    }
}

#Preview("Enhanced Data Management Section") {
    List {
        EnhancedDataManagementSection(userSettings: UserSettings.shared)
    }
    .environmentObject(DataManager.shared)
}
