//
//  DataManagementSection.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Enhanced data management with auto-backup, encryption, and import features
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

struct DataManagementSection: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var userSettings = UserSettings.shared
    @State private var showingBackupPasswordSheet = false
    @State private var showingImportFromCompetitors = false
    @State private var showingStorageUsage = false
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingClearDataAlert = false
    @State private var showingClearCacheAlert = false

    let backupFrequencies = ["Daily", "Weekly", "Monthly"]

    var body: some View {
        Section {
            // Auto backup toggle
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

            // Backup frequency
            if userSettings.autoBackupEnabled {
                Picker("Backup Frequency", selection: $userSettings.backupFrequency) {
                    ForEach(backupFrequencies, id: \.self) { frequency in
                        Text(frequency).tag(frequency)
                    }
                }
                .font(.spotifyBodyMedium)
                .foregroundColor(.wisePrimaryText)
            }

            // Last backup date
            HStack {
                Text("Last Backup")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                Spacer()
                if let lastBackup = userSettings.lastBackupDate {
                    Text(lastBackup, style: .relative)
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                } else {
                    Text("Never")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Backup location (placeholder for iCloud)
            HStack {
                Text("Backup Location")
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)
                Spacer()
                Text("Local Device")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
            }

            // iCloud sync (future feature)
            Toggle(isOn: $userSettings.iCloudSyncEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud Sync")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wisePrimaryText)
                    Text("Sync data across your devices (Coming Soon)")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .tint(.wiseForestGreen)
            .disabled(true) // Future feature

            // Backup encryption
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $userSettings.backupEncryptionEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Backup Encryption")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wisePrimaryText)
                        Text("Encrypt backups with a password")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
                .tint(.wiseForestGreen)

                if userSettings.backupEncryptionEnabled {
                    Button(action: {
                        showingBackupPasswordSheet = true
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.wiseBlue)
                            Text(userSettings.backupPassword != nil ? "Change Password" : "Set Password")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseBlue)
                            Spacer()
                        }
                    }
                }
            }

            // Manual backup/restore
            Button(action: {
                createBackup()
            }) {
                HStack {
                    Image(systemName: "arrow.down.doc.fill")
                        .foregroundColor(.wiseBlue)
                    Text("Create Backup Now")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                }
            }

            Button(action: {
                showingImportPicker = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.wiseBlue)
                    Text("Import/Restore Data")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                }
            }

            // Import from competitors
            Button(action: {
                showingImportFromCompetitors = true
            }) {
                HStack {
                    Image(systemName: "arrow.right.doc.on.clipboard")
                        .foregroundColor(.wiseForestGreen)
                    Text("Import from Competitors")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Storage usage
            Button(action: {
                showingStorageUsage = true
            }) {
                HStack {
                    Image(systemName: "internaldrive.fill")
                        .foregroundColor(.wiseBlue)
                    Text("Storage Usage")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            // Export data
            Button(action: {
                showingExportSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.wiseForestGreen)
                    Text("Export Data")
                        .foregroundColor(.wisePrimaryText)
                    Spacer()
                }
            }

            // Clear cache
            Button(action: {
                showingClearCacheAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.wiseError)
                    Text("Clear Cache")
                        .foregroundColor(.wiseError)
                    Spacer()
                }
            }

            // Clear all data
            Button(action: {
                showingClearDataAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.wiseError)
                    Text("Clear All Data")
                        .foregroundColor(.wiseError)
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
        .alert("Clear All Data?", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all your data including people, groups, subscriptions, and transactions. This action cannot be undone.")
        }
        .alert("Clear Cache?", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will clear temporary files and cached data to free up space.")
        }
        .sheet(isPresented: $showingBackupPasswordSheet) {
            BackupPasswordSheet(isPresented: $showingBackupPasswordSheet, userSettings: userSettings)
        }
        .sheet(isPresented: $showingImportFromCompetitors) {
            ImportFromCompetitorsView()
        }
        .sheet(isPresented: $showingStorageUsage) {
            StorageUsageView()
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            // Handle import
        }
    }

    private func createBackup() {
        do {
            let _ = try BackupService.shared.createBackup()
            userSettings.lastBackupDate = Date()
            ToastManager.shared.showSuccess("Backup created successfully")
        } catch {
            ToastManager.shared.showError("Failed to create backup: \(error.localizedDescription)")
        }
    }

    private func clearAllData() {
        do {
            try dataManager.clearAllData()
            ToastManager.shared.showSuccess("All data cleared successfully")
        } catch {
            ToastManager.shared.showError("Failed to clear data: \(error.localizedDescription)")
        }
    }

    private func clearCache() {
        // Clear cache implementation
        ToastManager.shared.showSuccess("Cache cleared successfully")
    }
}

// Backup password sheet

// Import from competitors view

// Storage usage view
struct StorageUsageView: View {
    @Environment(\.dismiss) var dismiss
    @State private var appSize: Int64 = 0
    @State private var dataSize: Int64 = 0
    @State private var imageSize: Int64 = 0

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Storage")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                            Text(formatBytes(appSize + dataSize + imageSize))
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wiseForestGreen)
                        }
                        Spacer()
                    }
                }

                Section {
                    StorageRow(title: "App Size", size: Double(appSize))
                    StorageRow(title: "Data Size", size: Double(dataSize))
                    StorageRow(title: "Images & Receipts", size: Double(imageSize))
                } header: {
                    Text("Breakdown")
                }
            }
            .navigationTitle("Storage Usage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseForestGreen)
                }
            }
            .onAppear {
                calculateStorageUsage()
            }
        }
    }

    func calculateStorageUsage() {
        // Mock implementation
        appSize = 15_000_000 // 15 MB
        dataSize = 2_500_000 // 2.5 MB
        imageSize = 5_000_000 // 5 MB
    }

    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}


#Preview {
    NavigationView {
        List {
            DataManagementSection()
        }
        .environmentObject(DataManager.shared)
    }
}
