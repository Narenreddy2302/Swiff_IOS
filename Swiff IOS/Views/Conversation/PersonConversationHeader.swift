//
//  PersonConversationHeader.swift
//  Swiff IOS
//
//  Compact header for person conversation view
//  Uses BaseConversationHeader for consistent styling
//

import SwiftUI

struct PersonConversationHeader: View {
    let person: Person
    var onBack: (() -> Void)?
    var onEdit: (() -> Void)?

    var body: some View {
        BaseConversationHeader(
            onBack: onBack,
            leading: {
                AvatarView(person: person, size: .medium, style: .solid)
            },
            title: {
                HeaderTitleView(title: person.name) {
                    BalanceText(balance: person.balance)
                }
            },
            trailing: {
                if let onEdit = onEdit {
                    Button(action: onEdit) {
                        Text("Edit")
                            .textActionButtonStyle()
                    }
                }
            }
        )
    }
}

