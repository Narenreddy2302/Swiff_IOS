//
//  PersonCard.swift
//  Swiff IOS
//
//  Clean row-based person display with initials avatar
//  Updated to match new unified list design
//

import SwiftUI

// MARK: - Person Card

/// Clean row-based person display with initials-based avatar.
/// Shows colored circle with initials, name, balance status, balance amount, and last activity.
/// Design: 44x44 avatar, 14pt gap, clean row without status badges.
struct PersonCard: View {
    let person: Person
    var transactions: [Transaction] = []

    // MARK: - Computed Properties

    private var initials: String {
        InitialsGenerator.generate(from: person.name)
    }

    private var avatarColor: Color {
        // Use pastel color based on name hash
        InitialsAvatarColors.color(for: person.name)
    }

    private var balanceText: String {
        String(format: "$%.2f", abs(person.balance))
    }

    private var balanceColor: Color {
        if person.balance > 0 {
            return AmountColors.positive // They owe you
        } else if person.balance < 0 {
            return AmountColors.negative // You owe them
        } else {
            return .wisePrimaryText
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
        HStack(spacing: 14) {
            // Initials avatar (no status badge)
            initialsAvatar

            // Name and status
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
                    .lineLimit(1)

                Text(balanceStatus)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .lineLimit(1)
            }

            Spacer()

            // Balance and last activity
            VStack(alignment: .trailing, spacing: 3) {
                Text(balanceText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(balanceColor)

                if !lastActivityText.isEmpty {
                    Text(lastActivityText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Initials Avatar

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)

            Text(initials)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
    }
}

// MARK: - Preview

#Preview("PersonCard - New Design") {
    VStack(spacing: 0) {
        // Settled
        PersonCard(
            person: {
                var p = Person(
                    name: "Aisha Patel",
                    email: "aisha@example.com",
                    phone: "",
                    avatarType: .initials("AP", colorIndex: 0)
                )
                p.balance = 0.00
                return p
            }()
        )

        AlignedDivider()

        // Person owes you money (green)
        PersonCard(
            person: {
                var p = Person(
                    name: "David Kim",
                    email: "david@example.com",
                    phone: "",
                    avatarType: .initials("DK", colorIndex: 1)
                )
                p.balance = 78.25
                return p
            }()
        )

        AlignedDivider()

        // Person owes you money (green)
        PersonCard(
            person: {
                var p = Person(
                    name: "Emma Wilson",
                    email: "emma@example.com",
                    phone: "",
                    avatarType: .initials("EW", colorIndex: 2)
                )
                p.balance = 45.50
                return p
            }()
        )

        AlignedDivider()

        // You owe them money (red)
        PersonCard(
            person: {
                var p = Person(
                    name: "James Chen",
                    email: "james@example.com",
                    phone: "",
                    avatarType: .initials("JC", colorIndex: 3)
                )
                p.balance = -32.00
                return p
            }()
        )

        AlignedDivider()

        // You owe them money (red)
        PersonCard(
            person: {
                var p = Person(
                    name: "Michael Taylor",
                    email: "michael@example.com",
                    phone: "",
                    avatarType: .initials("MT", colorIndex: 4)
                )
                p.balance = -25.00
                return p
            }()
        )
    }
    .background(Color.wiseCardBackground)
    .cornerRadius(12)
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.wiseGroupedBackground)
}
