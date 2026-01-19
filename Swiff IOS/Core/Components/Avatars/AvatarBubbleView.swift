//
//  AvatarBubbleView.swift
//  Swiff IOS
//
//  Created by Swiff AI on 01/18/26.
//  Reusable component for displaying person avatars with optional selection/removal state.
//

import SwiftUI

struct AvatarBubbleView: View {

    // MARK: - Properties

    let person: Person
    let size: CGFloat
    let isSelected: Bool
    var showRemoveButton: Bool = false
    var onRemove: (() -> Void)?

    init(
        person: Person,
        size: CGFloat = Theme.Metrics.avatarBubbleSize,
        isSelected: Bool = false,
        showRemoveButton: Bool = false,
        onRemove: (() -> Void)? = nil
    ) {
        self.person = person
        self.size = size
        self.isSelected = isSelected
        self.showRemoveButton = showRemoveButton
        self.onRemove = onRemove
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Avatar Bubble
            VStack(spacing: Theme.Metrics.spacingTiny) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.secondaryBackground)
                        .frame(width: size, height: size)

                    Text(person.initials)
                        .font(Theme.Fonts.labelMedium)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? Theme.Colors.brandPrimary : Color.clear,
                            lineWidth: Theme.Border.widthSelected)
                )

                Text(person.name.components(separatedBy: " ").first ?? person.name)
                    .font(Theme.Fonts.labelSmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(1)
                    .frame(width: size + Theme.Metrics.paddingSmall)
            }

            // Optional Remove Button
            if showRemoveButton {
                Button(action: {
                    onRemove?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .background(Theme.Colors.cardBackground.clipShape(Circle()))
                }
                .offset(x: 4, y: -4)
            }
        }
    }
}

#Preview {
    let mockPerson = Person(
        name: "John Doe",
        email: "john@example.com",
        phone: "555-1234",
        avatarType: .initials("JD", colorIndex: 0)
    )

    return HStack(spacing: 20) {
        AvatarBubbleView(
            person: mockPerson,
            isSelected: true)
        AvatarBubbleView(
            person: mockPerson,
            showRemoveButton: true)
    }
    .padding()
    .background(Theme.Colors.secondaryBackground)
}
