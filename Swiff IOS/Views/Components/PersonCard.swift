//
//  PersonCard.swift
//  Swiff IOS
//
//  Clean row-based person display with avatar, name, balance status, and activity
//

import SwiftUI

// MARK: - Person Card

/// Clean row-based person display.
/// Shows avatar, name, balance status, balance amount, and last activity.
struct PersonCard: View {
    let person: Person
    var transactions: [Transaction] = []
    var onTap: (() -> Void)? = nil

    // MARK: - Computed Properties

    private var balanceText: String {
        String(format: "$%.2f", abs(person.balance))
    }

    private var balanceColor: Color {
        if person.balance > 0 {
            return .wiseSuccess // They owe you
        } else if person.balance < 0 {
            return .wiseError // You owe them
        } else {
            return .wiseSecondaryText
        }
    }

    private var balanceStatus: String {
        if person.balance > 0 {
            return "Owes you"
        } else if person.balance < 0 {
            return "You owe"
        } else {
            return "Settled"
        }
    }

    private var lastActivityText: String {
        person.lastActivityText(transactions: transactions)
    }

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Avatar (clean design - no badge)
                avatar

                // Name and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(person.name)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    Text(balanceStatus)
                        .font(.spotifyBodySmall)
                        .foregroundColor(.wiseSecondaryText)
                }

                Spacer()

                // Balance and last activity
                VStack(alignment: .trailing, spacing: 4) {
                    Text(balanceText)
                        .font(.spotifyNumberMedium)
                        .foregroundColor(balanceColor)

                    if !lastActivityText.isEmpty {
                        Text(lastActivityText)
                            .font(.spotifyBodySmall)
                            .foregroundColor(.wiseSecondaryText)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.wiseCardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Avatar (Clean Design)

    private var avatar: some View {
        AvatarView(person: person, size: .large, style: .solid)
    }
}

// MARK: - Preview

#Preview("PersonCard") {
    VStack(spacing: 12) {
        // Person owes you money (green)
        PersonCard(
            person: {
                var p = Person(
                    name: "David Kim",
                    email: "david@example.com",
                    phone: "",
                    avatarType: .emoji("👨‍🔬")
                )
                p.balance = 78.25
                return p
            }()
        )

        // You owe them money (red)
        PersonCard(
            person: {
                var p = Person(
                    name: "James Chen",
                    email: "james@example.com",
                    phone: "",
                    avatarType: .emoji("👨‍💻")
                )
                p.balance = -32.00
                return p
            }()
        )

        // Settled (gray)
        PersonCard(
            person: {
                var p = Person(
                    name: "Aisha Patel",
                    email: "aisha@example.com",
                    phone: "",
                    avatarType: .emoji("👩‍💼")
                )
                p.balance = 0.00
                return p
            }()
        )
    }
    .padding()
    .background(Color.wiseGroupedBackground)
}
