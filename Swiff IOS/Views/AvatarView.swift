//
//  AvatarView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/18/25.
//  Flexible avatar component supporting photo, emoji, and initials
//

import SwiftUI

struct AvatarView: View {
    private let avatarType: AvatarType
    private let size: AvatarSize
    private let style: AvatarStyle

    // MARK: - Initializers

    /// Initialize with explicit avatar type
    init(avatarType: AvatarType, size: AvatarSize = .large, style: AvatarStyle = .gradient) {
        self.avatarType = avatarType
        self.size = size
        self.style = style
    }

    /// Initialize from Person model
    init(person: Person, size: AvatarSize = .large, style: AvatarStyle = .gradient) {
        self.avatarType = person.avatarType
        self.size = size
        self.style = style
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Content (avatar image, emoji, or initials)
            contentView
        }
        .frame(width: size.dimension, height: size.dimension)
        .clipShape(Circle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Background View

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .gradient:
            LinearGradient(
                colors: [
                    Color.wiseBrightGreen.opacity(0.2),
                    Color.wiseBrightGreen.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .solid:
            if case .initials(_, let colorIndex) = avatarType {
                AvatarColorPalette.color(for: colorIndex)
            } else {
                Color.wiseBrightGreen.opacity(0.1)
            }

        case .bordered:
            Color.white
                .overlay(
                    Circle()
                        .strokeBorder(Color.wiseBorder, lineWidth: 1)
                )
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch avatarType {
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size.fontSize))

        case .photo(let imageData):
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.dimension, height: size.dimension)
            } else {
                placeholderView
            }

        case .initials(let initials, _):
            Text(initials)
                .font(.system(size: size.fontSize, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray.opacity(0.5))
            .frame(width: size.dimension * 0.6, height: size.dimension * 0.6)
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        switch avatarType {
        case .emoji(let emoji):
            return "Avatar: \(emoji)"
        case .photo:
            return "Profile photo"
        case .initials(let initials, _):
            return "Avatar with initials \(initials)"
        }
    }
}

// MARK: - Preview

#Preview("Emoji Avatar") {
    VStack(spacing: 20) {
        AvatarView(avatarType: .emoji("😀"), size: .small, style: .solid)
        AvatarView(avatarType: .emoji("🎉"), size: .medium, style: .solid)
        AvatarView(avatarType: .emoji("🚀"), size: .large, style: .solid)
        AvatarView(avatarType: .emoji("🌟"), size: .xlarge, style: .solid)
    }
    .padding()
}

#Preview("Initials Avatar") {
    VStack(spacing: 20) {
        AvatarView(avatarType: .initials("JD", colorIndex: 0), size: .small, style: .solid)
        AvatarView(avatarType: .initials("AB", colorIndex: 1), size: .medium, style: .solid)
        AvatarView(avatarType: .initials("CD", colorIndex: 2), size: .large, style: .solid)
        AvatarView(avatarType: .initials("EF", colorIndex: 3), size: .xlarge, style: .solid)
    }
    .padding()
}

#Preview("Mixed Styles") {
    HStack(spacing: 20) {
        AvatarView(avatarType: .initials("JD", colorIndex: 0), size: .large, style: .gradient)
        AvatarView(avatarType: .initials("JD", colorIndex: 0), size: .large, style: .solid)
        AvatarView(avatarType: .initials("JD", colorIndex: 0), size: .large, style: .bordered)
    }
    .padding()
}
