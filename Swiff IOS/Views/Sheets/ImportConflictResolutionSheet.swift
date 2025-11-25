//
//  ImportConflictResolutionSheet.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  UI for resolving import data conflicts
//

import SwiftUI
import Combine

struct ImportConflictResolutionSheet: View {
    @Binding var selectedResolution: RestoreOptions.ConflictResolution
    @Binding var clearExistingData: Bool
    @Binding var isPresented: Bool

    let onConfirm: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.wiseAccentOrange)

                    Text("Import Conflict Resolution")
                        .font(.spotifyHeadingLarge)
                        .foregroundColor(.wisePrimaryText)

                    Text("Choose how to handle duplicate data when importing")
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 32)

                ScrollView {
                    VStack(spacing: 20) {
                        // Conflict Resolution Options
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Conflict Resolution")
                                .font(.spotifyLabelLarge)
                                .foregroundColor(.wiseSecondaryText)
                                .padding(.horizontal, 20)

                            // Keep Existing
                            ConflictResolutionOption(
                                isSelected: selectedResolution == RestoreOptions.ConflictResolution.keepExisting,
                                icon: "shield.checkered",
                                iconColor: .wiseBrightGreen,
                                title: "Keep Existing",
                                subtitle: "Skip duplicate items, keep your current data",
                                details: "Recommended if you want to preserve your local changes",
                                action: { selectedResolution = RestoreOptions.ConflictResolution.keepExisting }
                            )

                            // Replace with Backup
                            ConflictResolutionOption(
                                isSelected: selectedResolution == RestoreOptions.ConflictResolution.replaceWithBackup,
                                icon: "arrow.triangle.2.circlepath",
                                iconColor: .wiseAccentBlue,
                                title: "Replace with Backup",
                                subtitle: "Overwrite existing data with imported data",
                                details: "Use this to restore from a trusted backup",
                                action: { selectedResolution = RestoreOptions.ConflictResolution.replaceWithBackup }
                            )

                            // Merge by Date
                            ConflictResolutionOption(
                                isSelected: selectedResolution == .mergeByDate,
                                icon: "calendar.badge.clock",
                                iconColor: .wiseAccentOrange,
                                title: "Merge by Date",
                                subtitle: "Keep the most recently modified version",
                                details: "Smart merge based on modification dates",
                                action: { selectedResolution = .mergeByDate }
                            )
                        }

                        Divider()
                            .padding(.vertical, 8)

                        // Clear Existing Data Toggle
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Additional Options")
                                .font(.spotifyLabelLarge)
                                .foregroundColor(.wiseSecondaryText)
                                .padding(.horizontal, 20)

                            Toggle(isOn: $clearExistingData) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "trash.circle.fill")
                                            .foregroundColor(.wiseError)

                                        Text("Clear All Existing Data")
                                            .font(.spotifyBodyMedium)
                                            .foregroundColor(.wisePrimaryText)
                                    }

                                    Text("Delete all current data before importing (cannot be undone)")
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }
                            .tint(.wiseForestGreen)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(clearExistingData ? Color.wiseError.opacity(0.05) : Color.wiseBorder.opacity(0.3))
                            )
                            .padding(.horizontal, 20)
                        }

                        // Warning for Clear Data
                        if clearExistingData {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.wiseError)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Warning")
                                        .font(.spotifyLabelMedium)
                                        .foregroundColor(.wiseError)

                                    Text("This will permanently delete all existing data. Make sure you have a backup.")
                                        .font(.spotifyCaptionSmall)
                                        .foregroundColor(.wiseSecondaryText)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseError.opacity(0.1))
                                    .stroke(Color.wiseError, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 100)
                    }
                }

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        HapticManager.shared.success()
                        onConfirm()
                        isPresented = false
                    }) {
                        Text("Continue Import")
                            .font(.spotifyBodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.wiseForestGreen)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        HapticManager.shared.light()
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.wiseBorder.opacity(0.3))
                            .cornerRadius(12)
                    }
                }
                .padding(20)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -2)
            }
            .background(Color.wiseBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Conflict Resolution Option

struct ConflictResolutionOption: View {
    let isSelected: Bool
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let details: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.spotifyBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.wisePrimaryText)

                    Text(subtitle)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)

                    Text(details)
                        .font(.spotifyCaptionSmall)
                        .foregroundColor(.wiseSecondaryText.opacity(0.8))
                        .italic()
                }

                Spacer()

                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.wiseBrightGreen)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(Color.wiseBorder, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.05), radius: isSelected ? 8 : 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.wiseBrightGreen : Color.clear, lineWidth: 2)
                    )
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.smooth, value: isSelected)
    }
}

#Preview("Import Conflict Resolution") {
    @Previewable @State var selectedResolution: RestoreOptions.ConflictResolution = .replaceWithBackup
    @Previewable @State var clearExistingData: Bool = false
    @Previewable @State var isPresented: Bool = true
    
    ImportConflictResolutionSheet(
        selectedResolution: $selectedResolution,
        clearExistingData: $clearExistingData,
        isPresented: $isPresented,
        onConfirm: {
            print("Confirmed with resolution: \(selectedResolution)")
        }
    )
}
