//
//  ContactRowView.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Individual contact row for contacts list
//

import SwiftUI

struct ContactRowView: View {
    let contact: ContactEntry
    let onInvite: () -> Void
    var onSelect: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ContactAvatarView(contact: contact)

            // Name and Phone
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                if let phone = contact.primaryPhone {
                    Text(formatPhoneForDisplay(phone))
                        .font(.spotifyBodySmall)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Status Badge or Invite Button
            if contact.hasAppAccount {
                // On Swiff badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("On Swiff")
                        .font(.spotifyCaptionMedium)
                }
                .foregroundColor(Theme.Colors.success)
            } else if contact.canBeInvited {
                // Invite button
                Button(action: onInvite) {
                    Text("Invite")
                        .font(.spotifyLabelMedium)
                        .foregroundColor(Theme.Colors.brandPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.brandPrimary.opacity(0.1))
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Theme.Colors.cardBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect?()
        }
    }

    private func formatPhoneForDisplay(_ phone: String) -> String {
        // Simple format: keep the normalized phone but add some spacing
        guard phone.count >= 10 else { return phone }

        // If starts with +1, format as US
        if phone.hasPrefix("+1") && phone.count == 12 {
            let number = String(phone.dropFirst(2))
            let area = number.prefix(3)
            let first = number.dropFirst(3).prefix(3)
            let last = number.suffix(4)
            return "(\(area)) \(first)-\(last)"
        }

        return phone
    }
}

// MARK: - Contact Avatar View

struct ContactAvatarView: View {
    let contact: ContactEntry
    var size: CGFloat = 48

    var body: some View {
        if let imageData = contact.thumbnailImageData,
            let uiImage = UIImage(data: imageData)
        {
            // Photo avatar
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            // Initials avatar
            Circle()
                .fill(avatarColor.opacity(0.2))
                .frame(width: size, height: size)
                .overlay(
                    Text(contact.initials)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(avatarColor)
                )
        }
    }

    private var avatarColor: Color {
        // Use FeedAvatarColor for consistent styling
        FeedAvatarColor.forName(contact.name).foreground
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        ContactRowView(
            contact: ContactEntry(
                id: "1",
                name: "John Smith",
                phoneNumbers: ["+12025551234"],
                email: "john@example.com",
                thumbnailImageData: nil,
                hasAppAccount: true,
                matchedUserId: UUID()
            ),
            onInvite: {}
        )

        Divider()

        ContactRowView(
            contact: ContactEntry(
                id: "2",
                name: "Jane Doe",
                phoneNumbers: ["+12025555678"],
                email: "jane@example.com",
                thumbnailImageData: nil,
                hasAppAccount: false
            ),
            onInvite: {}
        )
    }
    .background(Theme.Colors.background)
}
