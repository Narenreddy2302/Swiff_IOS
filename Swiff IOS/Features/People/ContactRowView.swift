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
    var pendingBalance: Double? = nil  // Balance with this contact (positive = owes you)

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ContactAvatarView(contact: contact)

            // Name and Phone/Balance indicator
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.spotifyBodyLarge)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                // Show balance indicator if balance exists, otherwise show phone
                if let balance = pendingBalance, balance != 0 {
                    balanceIndicator(balance: balance)
                } else if let phone = contact.primaryPhone {
                    Text(formatPhoneForDisplay(phone))
                        .font(.spotifyBodySmall)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Right side: Balance amount OR Status Badge/Invite Button
            if let balance = pendingBalance, balance != 0 {
                // Show balance amount
                balanceAmountView(balance: balance)
            } else if contact.hasAppAccount {
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

    // MARK: - Balance Views

    private func balanceIndicator(balance: Double) -> some View {
        let isPositive = balance > 0
        let color = isPositive ? Theme.Colors.amountPositive : Theme.Colors.amountNegative
        let label = isPositive ? "Owes you" : "You owe"

        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(label)
                .font(.spotifyCaptionMedium)
                .foregroundColor(color)
        }
    }

    private func balanceAmountView(balance: Double) -> some View {
        let isPositive = balance > 0
        let formattedAmount = abs(balance).asCurrency
        let color = isPositive ? Theme.Colors.amountPositive : Theme.Colors.amountNegative
        let label = isPositive ? "owes you" : "you owe"

        return VStack(alignment: .trailing, spacing: 2) {
            Text(formattedAmount)
                .font(.spotifyBodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(label)
                .font(.spotifyCaptionMedium)
                .foregroundColor(Theme.Colors.textSecondary)
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

/// FIX 3.2: Updated to use lazy thumbnail loading via ContactThumbnailCache
struct ContactAvatarView: View {
    let contact: ContactEntry
    var size: CGFloat = 48

    /// Lazily loaded thumbnail image
    @State private var thumbnailImage: UIImage?

    /// Task for loading thumbnail (for cancellation on disappear)
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                // Photo avatar (lazy loaded)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Initials avatar (shown while loading or if no photo)
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
        .onAppear {
            loadThumbnailIfNeeded()
        }
        .onDisappear {
            // Cancel loading task when view disappears (scrolled off screen)
            loadTask?.cancel()
        }
    }

    /// Load thumbnail lazily using the cache
    private func loadThumbnailIfNeeded() {
        guard thumbnailImage == nil else { return }

        loadTask = Task {
            let image = await ContactThumbnailCache.shared.thumbnail(for: contact.id)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                thumbnailImage = image
            }
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
