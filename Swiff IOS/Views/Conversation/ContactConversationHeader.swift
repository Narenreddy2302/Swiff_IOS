//
//  ContactConversationHeader.swift
//  Swiff IOS
//
//  Compact header for contact conversation view
//  Uses BaseConversationHeader for consistent styling
//

import SwiftUI

struct ContactConversationHeader: View {
    let contact: ContactEntry
    let balance: Double?
    var onBack: (() -> Void)?

    var body: some View {
        BaseConversationHeader(
            onBack: onBack,
            leading: {
                ContactAvatarView(contact: contact, size: Theme.Metrics.avatarStandard)
            },
            title: {
                HeaderTitleView(
                    title: contact.name,
                    subtitle: subtitleText,
                    subtitleColor: subtitleColor
                ) {
                    if contact.hasAppAccount {
                        appBadge
                    }
                }
            },
            trailing: { EmptyView() }
        )
    }

    // MARK: - Computed Properties

    private var subtitleText: String {
        if let balance = balance, balance != 0 {
            if balance > 0 {
                return "Owes you \(formatCurrency(balance))"
            } else {
                return "You owe \(formatCurrency(abs(balance)))"
            }
        }

        if let phone = contact.primaryPhone {
            return formatPhoneForDisplay(phone)
        }

        return "No pending dues"
    }

    private var subtitleColor: Color {
        if let balance = balance, balance < 0 {
            return .wiseError
        }
        return .wiseSecondaryText
    }

    private var appBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.wiseBorder)
                .frame(width: 3, height: 3)

            Text("On Swiff")
                .font(Theme.Fonts.badgeText)
                .foregroundColor(.wiseBrightGreen)
        }
    }

    // MARK: - Helper Methods

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
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

#Preview("ContactConversationHeader - On Swiff") {
    ContactConversationHeader(
        contact: ContactEntry(
            id: "4",
            name: "Alice Brown",
            phoneNumbers: ["+12025550000"],
            email: nil,
            thumbnailImageData: nil,
            hasAppAccount: true
        ),
        balance: 0
    )
    .background(Color.wiseBackground)
}
