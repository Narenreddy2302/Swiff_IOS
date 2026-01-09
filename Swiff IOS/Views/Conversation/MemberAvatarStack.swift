//
//  MemberAvatarStack.swift
//  Swiff IOS
//
//  Overlapping avatar display for showing multiple participants
//  Used in Groups and Shared Subscriptions
//

import SwiftUI

// MARK: - Avatar Info Provider Protocol

/// Protocol for avatar information - allows any model to provide avatar data
/// Conforming types can be used with MemberAvatarStack without tight coupling
protocol AvatarInfoProvider {
    var id: UUID { get }
    var displayName: String { get }
    var avatarData: Data? { get }
    var avatarEmoji: String? { get }
    var avatarColor: Color { get }
}

extension AvatarInfoProvider {
    var initials: String {
        InitialsGenerator.generate(from: displayName)
    }
}

// MARK: - Member Avatar Stack

struct MemberAvatarStack: View {
    let members: [MemberAvatarInfo]
    var maxVisible: Int = 4
    var avatarSize: CGFloat = 32
    var overlap: CGFloat = 8
    var showNames: Bool = false

    private var visibleMembers: [MemberAvatarInfo] {
        Array(members.prefix(maxVisible))
    }

    private var extraCount: Int {
        max(0, members.count - maxVisible)
    }

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(visibleMembers.enumerated()), id: \.element.id) { index, member in
                memberAvatar(for: member)
                    .zIndex(Double(maxVisible - index))
            }

            if extraCount > 0 {
                extraCountBadge
                    .zIndex(0)
            }
        }
    }

    private func memberAvatar(for member: MemberAvatarInfo) -> some View {
        ZStack {
            Circle()
                .fill(member.avatarColor)
                .frame(width: avatarSize, height: avatarSize)

            if let photoData = member.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
            } else if let emoji = member.emoji {
                Text(emoji)
                    .font(.system(size: avatarSize * 0.5))
            } else {
                Text(member.initials)
                    .font(.system(size: avatarSize * 0.35, weight: .semibold))
                    .foregroundColor(.wisePrimaryText)
            }
        }
        .overlay(
            Circle()
                .stroke(Color.wiseCardBackground, lineWidth: 2)
        )
        .accessibilityLabel(member.name)
    }

    private var extraCountBadge: some View {
        ZStack {
            Circle()
                .fill(Color.wiseBorder)
                .frame(width: avatarSize, height: avatarSize)

            Text("+\(extraCount)")
                .font(.system(size: avatarSize * 0.35, weight: .semibold))
                .foregroundColor(.wisePrimaryText)
        }
        .overlay(
            Circle()
                .stroke(Color.wiseCardBackground, lineWidth: 2)
        )
        .accessibilityLabel("\(extraCount) more members")
    }
}

// MARK: - Member Avatar Info

struct MemberAvatarInfo: Identifiable {
    let id: UUID
    let name: String
    var photoData: Data?
    var emoji: String?
    var avatarColor: Color

    var initials: String {
        InitialsGenerator.generate(from: name)
    }

    init(
        id: UUID = UUID(),
        name: String,
        photoData: Data? = nil,
        emoji: String? = nil,
        avatarColor: Color? = nil
    ) {
        self.id = id
        self.name = name
        self.photoData = photoData
        self.emoji = emoji
        self.avatarColor = avatarColor ?? InitialsAvatarColors.color(for: name)
    }
}

// MARK: - Convenience Initializers

extension MemberAvatarStack {
    /// Initialize from Person array
    init(
        people: [Person],
        maxVisible: Int = 4,
        avatarSize: CGFloat = Theme.Metrics.avatarCompact,
        overlap: CGFloat = 8
    ) {
        self.members = people.map { person in
            MemberAvatarInfo(
                id: person.id,
                name: person.name,
                photoData: {
                    if case .photo(let data) = person.avatarType {
                        return data
                    }
                    return nil
                }(),
                emoji: {
                    if case .emoji(let emoji) = person.avatarType {
                        return emoji
                    }
                    return nil
                }(),
                avatarColor: InitialsAvatarColors.color(for: person.name)
            )
        }
        self.maxVisible = maxVisible
        self.avatarSize = avatarSize
        self.overlap = overlap
        self.showNames = false
    }

    /// Initialize from any AvatarInfoProvider conforming array
    init<T: AvatarInfoProvider>(
        providers: [T],
        maxVisible: Int = 4,
        avatarSize: CGFloat = Theme.Metrics.avatarCompact,
        overlap: CGFloat = 8
    ) {
        self.members = providers.map { provider in
            MemberAvatarInfo(
                id: provider.id,
                name: provider.displayName,
                photoData: provider.avatarData,
                emoji: provider.avatarEmoji,
                avatarColor: provider.avatarColor
            )
        }
        self.maxVisible = maxVisible
        self.avatarSize = avatarSize
        self.overlap = overlap
        self.showNames = false
    }
}

// MARK: - Small Avatar Stack (Inline)

struct SmallAvatarStack: View {
    let initials: [String]
    let colors: [Color]
    var maxVisible: Int = 3
    var avatarSize: CGFloat = 24
    var overlap: CGFloat = 6

    private var visibleInitials: [(String, Color)] {
        let limited = Array(zip(initials, colors).prefix(maxVisible))
        return limited.map { ($0.0, $0.1) }
    }

    private var extraCount: Int {
        max(0, initials.count - maxVisible)
    }

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(visibleInitials.enumerated()), id: \.offset) { index, item in
                smallAvatar(initials: item.0, color: item.1)
                    .zIndex(Double(maxVisible - index))
            }

            if extraCount > 0 {
                smallExtraBadge
                    .zIndex(0)
            }
        }
    }

    private func smallAvatar(initials: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: avatarSize, height: avatarSize)

            Text(initials)
                .font(.system(size: avatarSize * 0.4, weight: .semibold))
                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
        .overlay(
            Circle()
                .stroke(Color.wiseCardBackground, lineWidth: 1.5)
        )
    }

    private var smallExtraBadge: some View {
        ZStack {
            Circle()
                .fill(Color.wiseBorder)
                .frame(width: avatarSize, height: avatarSize)

            Text("+\(extraCount)")
                .font(.system(size: avatarSize * 0.4, weight: .semibold))
                .foregroundColor(.wisePrimaryText)
        }
        .overlay(
            Circle()
                .stroke(Color.wiseCardBackground, lineWidth: 1.5)
        )
    }
}

// MARK: - Preview

#Preview("Member Avatar Stacks") {
    VStack(spacing: 32) {
        VStack(alignment: .leading, spacing: 12) {
            Text("Standard (32pt)")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            MemberAvatarStack(
                members: [
                    MemberAvatarInfo(name: "Alex Thompson", avatarColor: InitialsAvatarColors.green),
                    MemberAvatarInfo(name: "Maria Santos", avatarColor: InitialsAvatarColors.pink),
                    MemberAvatarInfo(name: "John Davis", avatarColor: InitialsAvatarColors.purple),
                    MemberAvatarInfo(name: "Sarah Wilson", avatarColor: InitialsAvatarColors.yellow),
                    MemberAvatarInfo(name: "Mike Brown", avatarColor: InitialsAvatarColors.gray)
                ]
            )
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Large (48pt)")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            MemberAvatarStack(
                members: [
                    MemberAvatarInfo(name: "Alex Thompson", avatarColor: InitialsAvatarColors.green),
                    MemberAvatarInfo(name: "Maria Santos", avatarColor: InitialsAvatarColors.pink),
                    MemberAvatarInfo(name: "John Davis", avatarColor: InitialsAvatarColors.purple)
                ],
                avatarSize: 48,
                overlap: 12
            )
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Small Inline (24pt)")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            SmallAvatarStack(
                initials: ["AT", "MS", "JD", "SW", "MB", "CJ"],
                colors: [
                    InitialsAvatarColors.green,
                    InitialsAvatarColors.pink,
                    InitialsAvatarColors.purple,
                    InitialsAvatarColors.yellow,
                    InitialsAvatarColors.gray,
                    InitialsAvatarColors.green
                ]
            )
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Two Members")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            MemberAvatarStack(
                members: [
                    MemberAvatarInfo(name: "Alex Thompson", avatarColor: InitialsAvatarColors.green),
                    MemberAvatarInfo(name: "Maria Santos", avatarColor: InitialsAvatarColors.pink)
                ]
            )
        }

        Spacer()
    }
    .padding(16)
    .background(Color.wiseBackground)
}
