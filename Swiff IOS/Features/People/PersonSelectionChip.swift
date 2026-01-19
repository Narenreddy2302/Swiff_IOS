//
//  PersonSelectionChip.swift
//  Swiff IOS
//
//  Person chip for displaying selected person with remove option
//

import SwiftUI

struct PersonSelectionChip: View {
    let person: Person
    let showRemove: Bool
    let amount: Double?
    let onRemove: (() -> Void)?

    init(person: Person, showRemove: Bool = true, amount: Double? = nil, onRemove: (() -> Void)? = nil) {
        self.person = person
        self.showRemove = showRemove
        self.amount = amount
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                avatarType: person.avatarType,
                size: .small,
                style: .solid
            )
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wisePrimaryText)

                if let amount = amount {
                    Text(amount.asCurrency)
                        .font(.spotifyCaptionMedium)
                        .foregroundColor(.wiseSecondaryText)
                }
            }

            Spacer()

            if showRemove, let onRemove = onRemove {
                Button(action: {
                    HapticManager.shared.light()
                    onRemove()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.wiseSecondaryText)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(Color.wiseCardBackground)
        .cornerRadius(12)
    }
}

