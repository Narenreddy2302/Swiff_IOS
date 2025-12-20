//
//  PersonConversationHeader.swift
//  Swiff IOS
//
//  Compact header for person conversation view
//  80pt height with avatar, name, balance, and quick actions
//

import SwiftUI

struct PersonConversationHeader: View {
    let person: Person
    var onPhoneTap: (() -> Void)?
    var onMessageTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Avatar (64pt)
            AvatarView(person: person, size: .xlarge, style: .solid)

            // Person info
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.spotifyHeadingMedium)
                    .foregroundColor(.wisePrimaryText)

                // Balance summary
                balanceView
            }

            Spacer()

            // Quick action icons
            if !person.phone.isEmpty {
                HStack(spacing: 16) {
                    // Phone button
                    Button(action: {
                        HapticManager.shared.light()
                        onPhoneTap?()
                    }) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.wiseBrightGreen)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.wiseBrightGreen.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)

                    // Message button
                    Button(action: {
                        HapticManager.shared.light()
                        onMessageTap?()
                    }) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.wiseBlue)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.wiseBlue.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 80)
        .background(Color.wiseCardBackground)
    }

    private var balanceView: some View {
        HStack(spacing: 4) {
            if person.balance > 0 {
                Text("owes you")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                Text(String(format: "$%.2f", person.balance))
                    .font(.spotifyCaptionMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AmountColors.positive)
            } else if person.balance < 0 {
                Text("you owe")
                    .font(.spotifyCaptionMedium)
                    .foregroundColor(.wiseSecondaryText)
                Text(String(format: "$%.2f", abs(person.balance)))
                    .font(.spotifyCaptionMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AmountColors.negative)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.wiseBrightGreen)
                    Text("Settled up")
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        // Person owes you
        PersonConversationHeader(
            person: Person(
                name: "Alex Thompson",
                email: "alex@example.com",
                phone: "+1234567890",
                avatarType: .initials("AT", colorIndex: 0)
            ),
            onPhoneTap: {},
            onMessageTap: {}
        )

        Divider()

        // You owe person
        PersonConversationHeader(
            person: Person(
                name: "Maria Santos",
                email: "maria@example.com",
                phone: "+1234567890",
                avatarType: .initials("MS", colorIndex: 2)
            ),
            onPhoneTap: {},
            onMessageTap: {}
        )

        Divider()

        // Settled
        PersonConversationHeader(
            person: Person(
                name: "Jordan Lee",
                email: "jordan@example.com",
                phone: "+1234567890",
                avatarType: .initials("JL", colorIndex: 4)
            ),
            onPhoneTap: {},
            onMessageTap: {}
        )
    }
    .background(Color.wiseBackground)
}
