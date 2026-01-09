//
//  ContactConversationHeader.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Compact header for contact conversation view
//  70pt height with avatar, name, balance, and back button
//

import SwiftUI

struct ContactConversationHeader: View {
    let contact: ContactEntry
    let balance: Double?
    var onBack: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            // Back button (circular with gray filled background)
            if let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.wisePrimaryText)
                        .frame(width: 32, height: 32)
                        .background(Color.wiseBorder.opacity(0.3))
                        .clipShape(Circle())
                }
            }

            // Contact info (name + balance)
            VStack(alignment: .leading, spacing: 1) {
                Text(contact.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                // Balance summary
                balanceView
            }

            Spacer()

            // On Swiff badge (if applicable)
            if contact.hasAppAccount {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("On Swiff")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.wiseBrightGreen)
            }

            // Avatar on right (matching reference design)
            ContactAvatarView(contact: contact, size: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 70)
        .background(Color.wiseCardBackground)
        .overlay(
            Rectangle()
                .fill(Color.wiseBorder)
                .frame(height: 1)
            , alignment: .bottom
        )
    }

    @ViewBuilder
    private var balanceView: some View {
        if let balance = balance, balance != 0 {
            if balance > 0 {
                // Contact owes you - split into gray + green
                HStack(spacing: 4) {
                    Text("Owes you")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseSecondaryText)
                    Text("$\(String(format: "%.2f", balance))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AmountColors.positive)
                }
            } else {
                // You owe contact - split into gray + red
                HStack(spacing: 4) {
                    Text("You owe")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseSecondaryText)
                    Text("$\(String(format: "%.2f", abs(balance)))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.wiseError)
                }
            }
        } else {
            // No balance - show phone number or "No dues"
            if let phone = contact.primaryPhone {
                Text(formatPhoneForDisplay(phone))
                    .font(.system(size: 12))
                    .foregroundColor(.wiseSecondaryText)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseBrightGreen)
                    Text("No pending dues")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        }
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

#Preview("ContactConversationHeader - Owes You") {
    ContactConversationHeader(
        contact: ContactEntry(
            id: "1",
            name: "John Smith",
            phoneNumbers: ["+12025551234"],
            email: "john@example.com",
            thumbnailImageData: nil,
            hasAppAccount: false
        ),
        balance: 45.50
    )
    .background(Color.wiseBackground)
}

#Preview("ContactConversationHeader - You Owe") {
    ContactConversationHeader(
        contact: ContactEntry(
            id: "2",
            name: "Jane Doe",
            phoneNumbers: ["+12025555678"],
            email: nil,
            thumbnailImageData: nil,
            hasAppAccount: true
        ),
        balance: -25.00
    )
    .background(Color.wiseBackground)
}

#Preview("ContactConversationHeader - No Balance") {
    ContactConversationHeader(
        contact: ContactEntry(
            id: "3",
            name: "Bob Wilson",
            phoneNumbers: ["+12025559999"],
            email: nil,
            thumbnailImageData: nil,
            hasAppAccount: false
        ),
        balance: nil
    )
    .background(Color.wiseBackground)
}
