//
//  ProfileHeaderView.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/24/25.
//  Reusable profile header with avatar and user info
//

import SwiftUI

struct ProfileHeaderView: View {
    let profile: UserProfile
    let onEdit: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            Button(action: onEdit) {
                AvatarView(
                    avatarType: profile.avatarType,
                    size: .xxlarge,
                    style: .solid
                )
                .elevatedShadow()
                .transition(.opacity)
                .animation(reduceMotion ? .none : .easeInOut(duration: 0.2), value: profile.avatarType)
            }
            .accessibilityLabel("Profile picture")
            .accessibilityHint("Double tap to change your profile picture")
            .accessibilityAddTraits(.isButton)

            // Profile Information
            profileInfoSection

            // Edit Button
            SpotifyButton(
                "Edit Profile",
                icon: "pencil",
                variant: .secondary,
                size: .medium,
                action: onEdit
            )
            .accessibilityLabel("Edit profile")
            .accessibilityHint("Double tap to open profile editing screen")
        }
        .padding(.vertical, 24)
    }

    // MARK: - Profile Info Section

    @ViewBuilder
    private var profileInfoSection: some View {
        VStack(spacing: 8) {
            // Name
            Text(profile.name.isEmpty ? "Add Your Name" : profile.name)
                .font(.spotifyDisplayMedium)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: profile.name)

            // Email
            if !profile.email.isEmpty {
                Text(profile.email)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: profile.email)
            }

            // Phone
            if !profile.phone.isEmpty {
                Text(profile.phone)
                    .font(.spotifyBodyMedium)
                    .foregroundColor(.wiseSecondaryText)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: profile.phone)
            }

            // Member Since
            Text(formattedMemberSince(profile.createdDate))
                .font(.spotifyCaptionMedium)
                .foregroundColor(.wiseSecondaryText)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Helper Functions

    private func formattedMemberSince(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Member since \(formatter.string(from: date))"
    }

    private var accessibilityLabel: String {
        let name = profile.name.isEmpty ? "No name set" : profile.name
        let email = profile.email.isEmpty ? "" : ", \(profile.email)"
        let formattedDate = formattedMemberSince(profile.createdDate)
        return "Profile: \(name)\(email), \(formattedDate)"
    }
}

// MARK: - Preview

#Preview("Profile Header - Complete") {
    ProfileHeaderView(
        profile: UserProfile(
            name: "John Doe",
            email: "john.doe@example.com",
            phone: "+1 (555) 123-4567",
            avatarType: .initials("JD", colorIndex: 0),
            createdDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        ),
        onEdit: {
            print("Edit tapped")
        }
    )
    .padding()
}

#Preview("Profile Header - Minimal") {
    ProfileHeaderView(
        profile: UserProfile(
            name: "Jane Smith",
            email: "jane@example.com",
            phone: "",
            avatarType: .emoji("😊"),
            createdDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        ),
        onEdit: {
            print("Edit tapped")
        }
    )
    .padding()
}

#Preview("Profile Header - Empty") {
    ProfileHeaderView(
        profile: UserProfile(
            name: "",
            email: "",
            phone: "",
            avatarType: .initials("U", colorIndex: 0),
            createdDate: Date()
        ),
        onEdit: {
            print("Edit tapped")
        }
    )
    .padding()
}

#Preview("Profile Header - Dark Mode") {
    ProfileHeaderView(
        profile: UserProfile(
            name: "Alex Johnson",
            email: "alex@example.com",
            phone: "+1 (555) 987-6543",
            avatarType: .initials("AJ", colorIndex: 2),
            createdDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        ),
        onEdit: {
            print("Edit tapped")
        }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
