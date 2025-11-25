//
//  PINEntryView.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  PIN entry and confirmation screens
//

import SwiftUI
import Combine

// AGENT 5: PIN entry mode
enum PINEntryMode {
    case create
    case confirm
    case verify
}

// AGENT 5: PIN entry view for creating/confirming/verifying PIN
struct PINEntryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userSettings = UserSettings.shared

    let mode: PINEntryMode
    let existingPIN: String?
    let onComplete: (String) -> Void

    @State private var pin: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var title: String {
        switch mode {
        case .create: return "Create PIN"
        case .confirm: return "Confirm PIN"
        case .verify: return "Enter PIN"
        }
    }

    var subtitle: String {
        switch mode {
        case .create: return "Enter a 4-digit PIN"
        case .confirm: return "Re-enter your PIN to confirm"
        case .verify: return "Enter your PIN to continue"
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.wiseForestGreen)
                        .padding(.top, 40)

                    Text(title)
                        .font(.spotifyHeadingLarge)
                        .foregroundColor(.wisePrimaryText)

                    Text(subtitle)
                        .font(.spotifyBodyMedium)
                        .foregroundColor(.wiseSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // PIN dots
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < pin.count ? Color.wiseForestGreen : Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(.vertical, 20)

                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseError)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Number pad
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: 16) {
                            ForEach(1..<4, id: \.self) { col in
                                let number = row * 3 + col
                                NumberButton(number: "\(number)") {
                                    appendDigit("\(number)")
                                }
                            }
                        }
                    }

                    // Bottom row with 0 and delete
                    HStack(spacing: 16) {
                        Spacer()
                            .frame(width: 80, height: 80)

                        NumberButton(number: "0") {
                            appendDigit("0")
                        }

                        Button(action: deleteDigit) {
                            Image(systemName: "delete.left.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.wiseSecondaryText)
                                .frame(width: 80, height: 80)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.wiseForestGreen)
                }
            }
        }
    }

    // AGENT 5: Append digit to PIN
    private func appendDigit(_ digit: String) {
        guard pin.count < 4 else { return }

        pin += digit
        showError = false

        // Auto-submit when 4 digits entered
        if pin.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                validateAndSubmit()
            }
        }
    }

    // AGENT 5: Delete last digit
    private func deleteDigit() {
        guard !pin.isEmpty else { return }
        pin.removeLast()
        showError = false
    }

    // AGENT 5: Validate and submit PIN
    private func validateAndSubmit() {
        switch mode {
        case .create:
            // PIN created successfully
            onComplete(pin)

        case .confirm:
            // Verify PIN matches
            if let existingPIN = existingPIN, pin == existingPIN {
                onComplete(pin)
            } else {
                errorMessage = "PINs don't match. Try again."
                showError = true
                pin = ""
            }

        case .verify:
            // Verify against stored PIN
            if let existingPIN = existingPIN, pin == existingPIN {
                onComplete(pin)
            } else {
                errorMessage = "Incorrect PIN. Try again."
                showError = true
                pin = ""
            }
        }
    }
}

// AGENT 5: Number button component
struct NumberButton: View {
    let number: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.wisePrimaryText)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                )
        }
    }
}

#Preview {
    PINEntryView(mode: .create, existingPIN: nil) { pin in
        print("PIN created: \(pin)")
    }
}
