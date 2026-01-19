//
//  InviteSMSSheet.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Sheet for sending SMS invitations to contacts
//

import SwiftUI

struct InviteSMSSheet: View {
    let contact: ContactEntry
    @Binding var isPresented: Bool
    @State private var selectedPhone: String?
    @State private var showingCopiedToast = false

    // Placeholder App Store link - replace with actual link when published
    private let appStoreLink = "https://apps.apple.com/app/swiff"

    private var inviteMessage: String {
        "Hey! Join me on Swiff to easily split bills and track shared expenses. Download it here: \(appStoreLink)"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Invite \(contact.name)")
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            .padding(.top, 8)

            // Phone Selection (if multiple phones)
            if contact.phoneNumbers.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select phone number:")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(Theme.Colors.textSecondary)

                    ForEach(contact.phoneNumbers, id: \.self) { phone in
                        PhoneSelectionRow(
                            phone: phone,
                            isSelected: selectedPhone == phone || (selectedPhone == nil && phone == contact.primaryPhone)
                        ) {
                            selectedPhone = phone
                        }
                    }
                }
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                // Send SMS Button
                Button(action: sendSMS) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Send SMS Invite")
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(Theme.Colors.textOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.brandPrimary)
                    .cornerRadius(12)
                }

                // Copy Link Button
                Button(action: copyLink) {
                    HStack {
                        Image(systemName: showingCopiedToast ? "checkmark" : "doc.on.doc")
                        Text(showingCopiedToast ? "Copied!" : "Copy Invite Link")
                    }
                    .font(.spotifyLabelLarge)
                    .foregroundColor(Theme.Colors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.border)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Theme.Colors.cardBackground)
    }

    // MARK: - Actions

    private func sendSMS() {
        let phone = selectedPhone ?? contact.primaryPhone ?? ""
        let cleanPhone = phone.filter { $0.isNumber || $0 == "+" }

        guard !cleanPhone.isEmpty else { return }

        let encodedMessage = inviteMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "sms:\(cleanPhone)&body=\(encodedMessage)") {
            UIApplication.shared.open(url) { success in
                if success {
                    isPresented = false
                }
            }
        }
    }

    private func copyLink() {
        UIPasteboard.general.string = appStoreLink

        withAnimation {
            showingCopiedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingCopiedToast = false
            }
        }
    }
}

// MARK: - Phone Selection Row

struct PhoneSelectionRow: View {
    let phone: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Theme.Colors.brandPrimary : Theme.Colors.textTertiary)

                Text(formatPhoneForDisplay(phone))
                    .font(.spotifyBodyMedium)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Theme.Colors.brandPrimary.opacity(0.1) : Theme.Colors.border.opacity(0.5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatPhoneForDisplay(_ phone: String) -> String {
        guard phone.count >= 10 else { return phone }

        if phone.hasPrefix("+1") && phone.count == 12 {
            let number = String(phone.dropFirst(2))
            let area = number.prefix(3)
            let first = number.dropFirst(3).prefix(3)
            let last = number.suffix(4)
            return "(\(area)) \(first)-\(last)"
        }

        return phone
    }
}

// MARK: - Preview

#Preview {
    InviteSMSSheet(
        contact: ContactEntry(
            id: "1",
            name: "John Smith",
            phoneNumbers: ["+12025551234", "+12025555678"],
            email: "john@example.com",
            hasAppAccount: false
        ),
        isPresented: .constant(true)
    )
}
