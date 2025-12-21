//
//  SecuritySettingsSection.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Security settings section for biometrics, PIN, and auto-lock
//

import SwiftUI
import Combine

// AGENT 5: Security settings section (Tasks 5.1.1 - 5.1.12)
struct SecuritySettingsSection: View {
    @ObservedObject var userSettings: UserSettings
    @StateObject private var biometricService = BiometricAuthenticationService.shared

    @State private var showingPINCreate = false
    @State private var showingPINConfirm = false
    @State private var showingBiometricError = false
    @State private var biometricErrorMessage = ""
    @State private var pendingPIN: String?

    var body: some View {
        Section {
            // AGENT 5: Task 5.1.2 - Face ID/Touch ID lock toggle
            if biometricService.isAvailable {
                Toggle(isOn: Binding(
                    get: { userSettings.biometricAuthEnabled },
                    set: { newValue in
                        handleBiometricToggle(newValue)
                    }
                )) {
                    HStack {
                        Image(systemName: biometricService.biometricType.iconName)
                            .foregroundColor(.wiseForestGreen)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(biometricService.biometricType.displayName) Lock")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Text("Use \(biometricService.biometricType.displayName.lowercased()) to unlock app")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                }
                .tint(.wiseForestGreen)
            } else {
                // AGENT 5: Task 5.1.3 - Show unavailable state
                HStack {
                    Image(systemName: "faceid")
                        .foregroundColor(.wiseSecondaryText)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Biometric Lock")
                            .font(.spotifyBodyMedium)
                            .foregroundColor(.wiseSecondaryText)

                        Text("Not available on this device")
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }

                    Spacer()
                }
            }

            // AGENT 5: Task 5.1.6 - PIN lock option
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $userSettings.pinLockEnabled) {
                    HStack {
                        Image(systemName: "number.circle.fill")
                            .foregroundColor(.wiseBlue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("PIN Lock")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Text("Use 4-digit PIN to secure app")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                }
                .tint(.wiseForestGreen)

                // AGENT 5: Task 5.1.6 - Set PIN button
                if userSettings.pinLockEnabled {
                    Button(action: {
                        showingPINCreate = true
                    }) {
                        HStack {
                            Image(systemName: userSettings.encryptedPIN != nil ? "checkmark.circle.fill" : "plus.circle.fill")
                                .foregroundColor(.wiseForestGreen)

                            Text(userSettings.encryptedPIN != nil ? "Change PIN" : "Set PIN")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseForestGreen)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.wiseSecondaryText)
                        }
                        .padding(.leading, 32)
                    }
                    .disabled(!userSettings.pinLockEnabled)
                }
            }

            // AGENT 5: Task 5.1.10 - Auto-lock settings
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $userSettings.autoLockEnabled) {
                    HStack {
                        Image(systemName: "lock.rotation")
                            .foregroundColor(.wiseWarning)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-Lock")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)

                            Text("Lock app after inactivity")
                                .font(.spotifyCaptionMedium)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                }
                .tint(.wiseForestGreen)

                // AGENT 5: Task 5.1.11 - Lock after duration picker
                if userSettings.autoLockEnabled {
                    Picker("Lock After", selection: $userSettings.autoLockDuration) {
                        Text("1 Minute").tag(60)
                        Text("5 Minutes").tag(300)
                        Text("15 Minutes").tag(900)
                        Text("30 Minutes").tag(1800)
                        Text("Never").tag(0)
                    }
                    .pickerStyle(.menu)
                    .padding(.leading, 32)
                }
            }
        } header: {
            // AGENT 5: Task 5.1.1 - Security section header
            Text("Security")
                .font(.spotifyLabelSmall)
                .foregroundColor(.wiseSecondaryText)
        } footer: {
            Text("Protect your financial data with biometric authentication or PIN. Auto-lock will secure the app when inactive.")
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
        }
        .sheet(isPresented: $showingPINCreate) {
            // AGENT 5: Task 5.1.7 - 4-digit PIN entry screen
            PINEntryView(mode: .create, existingPIN: nil) { pin in
                pendingPIN = pin
                showingPINCreate = false
                showingPINConfirm = true
            }
        }
        .sheet(isPresented: $showingPINConfirm) {
            // AGENT 5: Task 5.1.8 - Confirm PIN screen
            PINEntryView(mode: .confirm, existingPIN: pendingPIN) { pin in
                // AGENT 5: Task 5.1.9 - Store encrypted PIN
                let encryptedPIN = PINEncryptionHelper.shared.encrypt(pin: pin)
                userSettings.encryptedPIN = encryptedPIN
                showingPINConfirm = false
                pendingPIN = nil
                ToastManager.shared.showSuccess("PIN set successfully")
            }
        }
        .alert("Biometric Authentication Error", isPresented: $showingBiometricError) {
            Button("OK") {
                showingBiometricError = false
            }
        } message: {
            Text(biometricErrorMessage)
        }
    }

    // AGENT 5: Task 5.1.4 - Request biometric permission on first toggle
    private func handleBiometricToggle(_ newValue: Bool) {
        if newValue {
            // Request permission
            Task {
                do {
                    let success = try await biometricService.requestPermission()
                    if success {
                        await MainActor.run {
                            // AGENT 5: Task 5.1.5 - Store preference in UserSettings
                            userSettings.biometricAuthEnabled = true
                            ToastManager.shared.showSuccess("\(biometricService.biometricType.displayName) enabled")
                        }
                    }
                } catch {
                    await MainActor.run {
                        biometricErrorMessage = error.localizedDescription
                        showingBiometricError = true
                        userSettings.biometricAuthEnabled = false
                    }
                }
            }
        } else {
            userSettings.biometricAuthEnabled = false
        }
    }
}

#Preview("Security Settings Section") {
    List {
        SecuritySettingsSection(userSettings: UserSettings.shared)
    }
}
