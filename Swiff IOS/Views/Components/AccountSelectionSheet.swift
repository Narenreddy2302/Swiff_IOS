//
//  AccountSelectionSheet.swift
//  Swiff IOS
//
//  Bottom sheet for selecting a payment account
//

import SwiftUI

struct AccountSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    @Binding var selectedAccount: Account?
    let onAccountSelected: (Account) -> Void

    @State private var showingAddAccount = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Account")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                Spacer()

                Button(action: {
                    HapticManager.shared.light()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.wiseSecondaryText.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .background(Color.wiseBorder)

            // Account List
            ScrollView {
                VStack(spacing: 8) {
                    if dataManager.accounts.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.wiseSecondaryText.opacity(0.4))

                            Text("No accounts yet")
                                .font(.spotifyBodyLarge)
                                .foregroundColor(.wiseSecondaryText)

                            Text("Add your first payment account")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseTertiaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(dataManager.accounts) { account in
                            AccountRow(
                                account: account,
                                isSelected: selectedAccount?.id == account.id,
                                onSelect: {
                                    HapticManager.shared.selection()
                                    onAccountSelected(account)
                                    dismiss()
                                }
                            )
                        }
                    }

                    // Add Account Button
                    Button(action: {
                        HapticManager.shared.impact(.light)
                        showingAddAccount = true
                    }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.wiseBrightGreen.opacity(0.1))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.wiseBrightGreen)
                            }

                            Text("Add New Account")
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wiseBrightGreen)

                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                .foregroundColor(Color.wiseBrightGreen.opacity(0.3))
                        )
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .background(Color.wiseCardBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .sheet(isPresented: $showingAddAccount) {
            AddAccountSheet()
        }
    }
}

// MARK: - Account Row

struct AccountRow: View {
    let account: Account
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Account Type Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(account.type.color.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: account.type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(account.type.color)
                }

                // Account Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(account.name)
                            .font(.spotifyBodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.wisePrimaryText)

                        if account.isDefault {
                            Text("Default")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseBrightGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.wiseBrightGreen.opacity(0.1))
                                )
                        }
                    }

                    if !account.number.isEmpty {
                        Text(account.number)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    } else {
                        Text(account.type.rawValue)
                            .font(.spotifyCaptionMedium)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }

                Spacer()

                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.wiseForestGreen)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.wiseForestGreen.opacity(0.05) : Color.wiseCardBackground)
                    .stroke(isSelected ? Color.wiseForestGreen : Color.wiseBorder, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Account Sheet

struct AddAccountSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    @State private var name = ""
    @State private var number = ""
    @State private var selectedType: AccountType = .bank
    @State private var isDefault = false

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Account Type Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account Type")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(AccountType.allCases, id: \.self) { type in
                                Button(action: { selectedType = type }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(type.color)

                                        Text(type.shortName)
                                            .font(.spotifyBodySmall)
                                            .foregroundColor(.wisePrimaryText)

                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedType == type ? type.color.opacity(0.1) : Color.wiseBorder.opacity(0.5))
                                            .stroke(selectedType == type ? type.color : Color.clear, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                    }

                    // Account Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account Details")
                            .font(.spotifyHeadingMedium)
                            .foregroundColor(.wisePrimaryText)

                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Account Name *")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., Chase Checking", text: $name)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                        }

                        // Last 4 digits (optional)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Last 4 Digits (Optional)")
                                .font(.spotifyLabelMedium)
                                .foregroundColor(.wiseSecondaryText)

                            TextField("e.g., 4521", text: $number)
                                .font(.spotifyBodyMedium)
                                .foregroundColor(.wisePrimaryText)
                                .keyboardType(.numberPad)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.wiseBorder.opacity(0.5))
                                        .stroke(Color.wiseBorder, lineWidth: 1)
                                )
                                .onChange(of: number) { oldValue, newValue in
                                    // Limit to 4 digits
                                    if newValue.count > 4 {
                                        number = String(newValue.prefix(4))
                                    }
                                }

                            Text("For easy identification (stored as ••\(number.isEmpty ? "XXXX" : number))")
                                .font(.spotifyCaptionSmall)
                                .foregroundColor(.wiseTertiaryText)
                        }

                        // Default Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Set as Default")
                                    .font(.spotifyBodyMedium)
                                    .foregroundColor(.wisePrimaryText)

                                Text("Use this account by default")
                                    .font(.spotifyCaptionMedium)
                                    .foregroundColor(.wiseSecondaryText)
                            }

                            Spacer()

                            Toggle("", isOn: $isDefault)
                                .tint(.wiseForestGreen)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wiseBorder.opacity(0.5))
                                .stroke(Color.wiseBorder, lineWidth: 1)
                        )
                    }

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(.wiseSecondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addAccount()
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(isFormValid ? .white : .wiseSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isFormValid ? Color.wiseForestGreen : Color.wiseBorder)
                    )
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private func addAccount() {
        let maskedNumber = number.isEmpty ? "" : "••\(number)"

        let newAccount = Account(
            name: name.trimmingCharacters(in: .whitespaces),
            number: maskedNumber,
            type: selectedType,
            isDefault: isDefault || dataManager.accounts.isEmpty // First account is auto-default
        )

        do {
            try dataManager.addAccount(newAccount)
            HapticManager.shared.success()
            dismiss()
        } catch {
            dataManager.error = error
        }
    }
}

// MARK: - Preview

#Preview("Account Selection Sheet") {
    AccountSelectionSheet(
        selectedAccount: .constant(nil),
        onAccountSelected: { _ in }
    )
    .environmentObject(DataManager.shared)
}

#Preview("Add Account Sheet") {
    AddAccountSheet()
        .environmentObject(DataManager.shared)
}
