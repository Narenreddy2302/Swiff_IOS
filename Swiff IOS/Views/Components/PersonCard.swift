//
//  PersonCard.swift
//  Swiff IOS
//
//  Card-based person display with avatar, balance, and last activity
//

import SwiftUI

// MARK: - Person Card

/// Card-based person display with avatar, balance, and last activity.
/// Shows balance direction: "Owes you" (green) or "You owe" (red)
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
            return .wiseBrightGreen // They owe you
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
                // Avatar
                AvatarView(person: person, size: .large, style: .solid)

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    // Name
                    Text(person.name)
                        .font(.spotifyBodyLarge)
                        .foregroundColor(.wisePrimaryText)
                        .lineLimit(1)

                    // Balance Status Line
                    HStack(spacing: 4) {
                        Text(balanceStatus)
                            .font(.spotifyBodySmall)
                            .foregroundColor(balanceColor)

                        if !lastActivityText.isEmpty {
                            Text("•")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)

                            Text("Last activity \(lastActivityText)")
                                .font(.spotifyBodySmall)
                                .foregroundColor(.wiseSecondaryText)
                        }
                    }
                    .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Balance Amount
                Text(balanceText)
                    .font(.spotifyNumberMedium)
                    .foregroundColor(balanceColor)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.wiseCardBackground)
            .cornerRadius(16)
            .cardShadow()
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Preview

#Preview("PersonCard") {
    VStack(spacing: 12) {
        PersonCard(
            person: {
                var p = Person(
                    name: "John Doe",
                    email: "john@example.com",
                    phone: "",
                    avatarType: .initials("JD", colorIndex: 0)
                )
                p.balance = 150.00
                return p
            }()
        )

        PersonCard(
            person: {
                var p = Person(
                    name: "Jane Smith",
                    email: "jane@example.com",
                    phone: "",
                    avatarType: .initials("JS", colorIndex: 2)
                )
                p.balance = -75.50
                return p
            }()
        )
    }
    .padding()
    .background(Color.wiseGroupedBackground)
}
