//
//  SettingsView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Settings and preferences view
//

import Combine
import PhotosUI
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var showingExportSheet = false
    @State private var showingClearDataAlert = false
    @State private var showingBackupSuccess = false
    @State private var showingImportPicker = false
    @State private var showingConflictResolution = false
    @State private var showingRestoreSuccess = false
    @State private var restoreStatistics: RestoreStatistics?
    @State private var showingProfileEdit = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingAppIconPicker = false

    // Import/Restore options
    @State private var selectedResolution: RestoreOptions.ConflictResolution = RestoreOptions
        .ConflictResolution.replaceWithBackup
    @State private var clearExistingData: Bool = false
    @State private var pendingImportURL: URL?

    let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "INR"]
    let appVersion = "1.0.0"

    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    Button(action: {
                        showingProfileEdit = true
                    }) {
                        HStack(spacing: 16) {
                            // Profile Avatar
                            AvatarView(
                                avatarType: profileManager.profile.avatarType,
                                size: .xlarge,
                                style: .solid
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(
                                    profileManager.profile.name.isEmpty
                                        ? "Set Your Name" : profileManager.profile.name
                                )
                                .font(.spotifyHeadingMedium)
                                .foregroundColor(.wisePrimaryText)

                                Text(
                                    profileManager.profile.email.isEmpty
                                        ? "Tap to edit profile" : profileManager.profile.email
                                )
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Profile")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                // Appearance Section

                Section {
                    // App Icon Picker
                    Button(action: {
                        showingAppIconPicker = true
                    }) {
                        HStack {
                            Image(systemName: "app.fill")
                                .foregroundColor(.wiseBlue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("App Icon")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)
                                Text("Personalize your home screen")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                } header: {
                    Text("Appearance")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                // Currency Section
                Section {
                    Picker("Currency", selection: $userSettings.selectedCurrency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Preferences")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)
                } footer: {
                    Text("Choose your preferred currency for displaying amounts")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }

                // Data Management Section
                Section {
                    Button(action: {
                        createBackup()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.doc.fill")
                                .foregroundColor(.wiseBlue)
                            Text("Create Backup")
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

                // About Section
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.wisePrimaryText)
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundColor(.wisePrimaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }

                    Button(action: {
                        showingTermsOfService = true
                    }) {
                        HStack {
                            Text("Terms of Service")
                                .foregroundColor(.wisePrimaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                } header: {
                    Text("About")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
        .alert("Clear All Data?", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text(
                "This will permanently delete all your data including people, groups, subscriptions, and transactions. This action cannot be undone."
            )
        }
        .alert("Backup Created", isPresented: $showingBackupSuccess) {
            Button("OK") {}
        } message: {
            Text("Your data has been backed up successfully.")
        }
        .alert("Restore Completed", isPresented: $showingRestoreSuccess) {
            Button("OK") {}
        } message: {
            if let stats = restoreStatistics {
                Text(
                    "Successfully imported \(stats.recordsImported) records, skipped \(stats.recordsSkipped), replaced \(stats.recordsReplaced)."
                )
            } else {
                Text("Your data has been restored successfully.")
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
        }
        .sheet(isPresented: $showingProfileEdit) {
            UserProfileEditView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingAppIconPicker) {
            AppIconPickerView()
        }
        .sheet(isPresented: $showingConflictResolution) {
            ImportConflictResolutionSheet(
                selectedResolution: $selectedResolution,
                clearExistingData: $clearExistingData,
                isPresented: $showingConflictResolution,
                onConfirm: performImport
            )
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }

    // MARK: - Helper Functions

    private func createBackup() {
        do {
            _ = try BackupService.shared.createBackup()
            ToastManager.shared.showSuccess("Backup created successfully")
            showingBackupSuccess = true
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

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Store URL and show conflict resolution sheet
            pendingImportURL = url
            showingConflictResolution = true

        case .failure(let error):
            ToastManager.shared.showError("Failed to import file: \(error.localizedDescription)")
        }
    }

    private func performImport() {
        guard let url = pendingImportURL else { return }

        do {
            // Create restore options based on user selection
            let restoreOptions = RestoreOptions(
                conflictResolution: selectedResolution,
                clearExistingData: clearExistingData,
                validateBeforeRestore: true
            )

            // Restore from backup
            let stats = try BackupService.shared.restoreFromBackup(
                url: url,
                options: restoreOptions
            )

            // Reload data in DataManager
            Task {
                dataManager.loadAllData()
            }

            // Show success message
            restoreStatistics = stats
            showingRestoreSuccess = true
            ToastManager.shared.showSuccess("Data restored successfully")

            // Clear pending URL
            pendingImportURL = nil

        } catch {
            ToastManager.shared.showError("Failed to restore data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var exportFormat: ExportFormat = .json
    @State private var showingShareSheet = false
    @State private var exportURL: URL?

    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Export Format")
                        .font(.spotifyLabelSmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Section {
                    Text("This will export all your data including:")
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("\(dataManager.peopleCount) people", systemImage: "person.2.fill")
                        Label("\(dataManager.groupsCount) groups", systemImage: "person.3.fill")
                        Label(
                            "\(dataManager.subscriptionsCount) subscriptions",
                            systemImage: "creditcard.fill")
                        Label(
                            "\(dataManager.transactionsCount) transactions",
                            systemImage: "list.bullet")
                    }
                    .font(.spotifyBodySmall)
                    .foregroundColor(.wisePrimaryText)
                }

                Section {
                    Button(action: exportData) {
                        HStack {
                            Spacer()
                            Text("Export Data")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(Color.wiseForestGreen)
                        .cornerRadius(12)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportData() {
        do {
            let url: URL

            if exportFormat == .csv {
                // Export as CSV
                url = try CSVExportService.shared.exportAllToCSV()
            } else {
                // Export as JSON
                let options = BackupOptions(
                    includePeople: true,
                    includeGroups: true,
                    includeSubscriptions: true,
                    includeTransactions: true,
                    prettyPrintJSON: true
                )
                url = try BackupService.shared.exportForSharing(options: options)
            }

            exportURL = url
            showingShareSheet = true
            ToastManager.shared.showSuccess("Export ready to share")
        } catch {
            ToastManager.shared.showError("Failed to export data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Settings - Default") {
    SettingsView()
        .environmentObject(DataManager.shared)
}

#Preview("Settings - Dark Mode") {
    SettingsView()
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
