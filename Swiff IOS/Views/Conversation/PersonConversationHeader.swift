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

// MARK: - Preview

#Preview("PersonConversationHeader - Owes You") {
    PersonConversationHeader(
        person: MockData.personOwedMoney
    )
    .background(Color.wiseBackground)
}

#Preview("PersonConversationHeader - You Owe") {
    PersonConversationHeader(
        person: MockData.personOwingMoney
    )
    .background(Color.wiseBackground)
}

#Preview("PersonConversationHeader - Settled") {
    PersonConversationHeader(
        person: MockData.personSettled
    )
    .background(Color.wiseBackground)
}

#Preview("PersonConversationHeader - Long Name") {
    PersonConversationHeader(
        person: MockData.longNamePerson
    )
    .background(Color.wiseBackground)
}

#Preview("PersonConversationHeader - With Edit") {
    PersonConversationHeader(
        person: MockData.personOwedMoney,
        onEdit: {}
    )
    .background(Color.wiseBackground)
}
