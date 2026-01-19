//
//  UserProfile.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Updated on 01/10/26 to sync with Supabase user_profiles table
//  User profile model for storing user information
//

import Combine
import Foundation
import SwiftUI

struct UserProfile: Codable, Identifiable {
    var id: UUID
    var name: String
    var email: String
    var phone: String
    var avatarType: AvatarType
    var createdDate: Date
    var lastModifiedDate: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        email: String = "",
        phone: String = "",
        avatarType: AvatarType = .initials("U", colorIndex: 0),
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.avatarType = avatarType
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
    }

    /// Initialize from Supabase profile
    init(from supabaseProfile: SupabaseUserProfile) {
        self.id = supabaseProfile.id
        self.name = supabaseProfile.name
        self.email = supabaseProfile.email
        self.phone = supabaseProfile.phone ?? ""
        self.createdDate = supabaseProfile.createdAt
        self.lastModifiedDate = supabaseProfile.updatedAt

        // Convert Supabase avatar type to local AvatarType
        if let avatarTypeStr = supabaseProfile.avatarType {
            switch avatarTypeStr {
            case "emoji":
                if let emoji = supabaseProfile.avatarEmoji {
                    self.avatarType = .emoji(emoji)
                } else {
                    self.avatarType = .initials(
                        supabaseProfile.computedInitials,
                        colorIndex: supabaseProfile.avatarColorIndex ?? 0
                    )
                }
            case "initials":
                self.avatarType = .initials(
                    supabaseProfile.avatarInitials ?? supabaseProfile.computedInitials,
                    colorIndex: supabaseProfile.avatarColorIndex ?? 0
                )
            case "photo":
                // For photo type, fall back to initials for now
                // TODO: Support photo URLs when implemented
                self.avatarType = .initials(
                    supabaseProfile.computedInitials,
                    colorIndex: supabaseProfile.avatarColorIndex ?? 0
                )
            default:
                self.avatarType = .initials(
                    supabaseProfile.computedInitials,
                    colorIndex: supabaseProfile.avatarColorIndex ?? 0
                )
            }
        } else {
            self.avatarType = .initials(
                supabaseProfile.computedInitials,
                colorIndex: supabaseProfile.avatarColorIndex ?? 0
            )
        }
    }

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = String(components[0].prefix(1))
            let last = String(components[1].prefix(1))
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "U"
    }
}

// MARK: - UserProfile Manager (Supabase-synced)

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()

    @Published var profile: UserProfile
    @Published var isLoading: Bool = false
    @Published var isSynced: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let authService = SupabaseAuthService.shared

    // Local cache keys for offline support
    private let userDefaults = UserDefaults.standard
    private let profileCacheKey = "UserProfileCache"

    private init() {
        // Initialize profile with default first (required before calling instance methods)
        self.profile = UserProfile(name: "User")

        // Then load cached profile if available
        if let data = userDefaults.data(forKey: profileCacheKey),
            let cachedProfile = try? JSONDecoder().decode(UserProfile.self, from: data)
        {
            self.profile = cachedProfile
        }

        // Observe Supabase auth service for profile changes
        setupSupabaseObserver()
    }

    // MARK: - Supabase Sync

    private func setupSupabaseObserver() {
        // Observe currentUserProfile from SupabaseAuthService
        authService.$currentUserProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] supabaseProfile in
                guard let self = self else { return }

                if let supabaseProfile = supabaseProfile {
                    // Update local profile from Supabase
                    let updatedProfile = UserProfile(from: supabaseProfile)
                    self.profile = updatedProfile
                    self.isSynced = true

                    // Cache for offline use
                    self.cacheProfile(updatedProfile)

                    print("✅ Profile synced from Supabase: \(updatedProfile.name)")
                } else {
                    // User logged out or no profile
                    self.isSynced = false
                }
            }
            .store(in: &cancellables)
    }

    /// Refresh profile from Supabase
    func refreshProfile() async {
        isLoading = true
        // SupabaseAuthService will fetch and publish the profile
        // which triggers our observer
        await authService.fetchUserProfile()
        isLoading = false
    }

    // MARK: - Profile Updates (saves to Supabase)

    func updateProfile(_ newProfile: UserProfile) {
        Task {
            await updateProfileAsync(newProfile)
        }
    }

    func updateProfileAsync(_ newProfile: UserProfile) async {
        isLoading = true

        do {
            // Determine avatar type string and related fields
            var avatarTypeStr: String?
            var avatarEmoji: String?
            var avatarInitials: String?
            var avatarColorIndex: Int?

            switch newProfile.avatarType {
            case .emoji(let emoji):
                avatarTypeStr = "emoji"
                avatarEmoji = emoji
            case .initials(let initials, let colorIdx):
                avatarTypeStr = "initials"
                avatarInitials = initials
                avatarColorIndex = colorIdx
            case .photo(_):
                avatarTypeStr = "photo"
            }

            // Save to Supabase
            try await authService.updateProfile(
                name: newProfile.name,
                phone: newProfile.phone.isEmpty ? nil : newProfile.phone,
                avatarType: avatarTypeStr,
                avatarEmoji: avatarEmoji,
                avatarInitials: avatarInitials,
                avatarColorIndex: avatarColorIndex
            )

            // Update local profile immediately
            await MainActor.run {
                var updatedProfile = newProfile
                updatedProfile.lastModifiedDate = Date()
                self.profile = updatedProfile
                self.cacheProfile(updatedProfile)
                self.isLoading = false
                self.isSynced = true
            }

            print("✅ Profile saved to Supabase")

        } catch {
            await MainActor.run {
                self.isLoading = false
                // Still update locally for offline support
                var updatedProfile = newProfile
                updatedProfile.lastModifiedDate = Date()
                self.profile = updatedProfile
                self.cacheProfile(updatedProfile)
                self.isSynced = false
            }
            print("⚠️ Failed to save profile to Supabase: \(error)")
        }
    }

    func updateName(_ name: String) async {
        var updatedProfile = profile
        updatedProfile.name = name
        await updateProfileAsync(updatedProfile)
    }

    func updatePhone(_ phone: String) async {
        var updatedProfile = profile
        updatedProfile.phone = phone
        await updateProfileAsync(updatedProfile)
    }

    func updateAvatar(_ avatarType: AvatarType) async {
        var updatedProfile = profile
        updatedProfile.avatarType = avatarType
        await updateProfileAsync(updatedProfile)
    }

    // MARK: - Local Cache (for offline support)

    private func cacheProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            userDefaults.set(encoded, forKey: profileCacheKey)
        }
    }

    private func loadCachedProfile() -> UserProfile? {
        if let data = userDefaults.data(forKey: profileCacheKey),
            let decoded = try? JSONDecoder().decode(UserProfile.self, from: data)
        {
            return decoded
        }
        return nil
    }

    // MARK: - Legacy Support (for existing code)

    func saveProfile() {
        // Trigger Supabase save
        updateProfile(profile)
    }

    func resetProfile() {
        self.profile = UserProfile(name: "User")
        cacheProfile(profile)
        // Note: This doesn't delete from Supabase, just resets local
    }
}
