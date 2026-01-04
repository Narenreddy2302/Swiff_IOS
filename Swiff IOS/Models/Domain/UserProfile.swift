//
//  UserProfile.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  User profile model for storing user information
//

import Foundation
import SwiftUI
import Combine

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

// MARK: - UserProfile Manager

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()

    @Published var profile: UserProfile

    private let userDefaults = UserDefaults.standard
    private let profileKey = "UserProfile"

    private init() {
        // Try to load saved profile
        if let data = userDefaults.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            // Create default profile
            self.profile = UserProfile(name: "User")
        }
    }

    func updateProfile(_ newProfile: UserProfile) {
        var updatedProfile = newProfile
        updatedProfile.lastModifiedDate = Date()
        self.profile = updatedProfile
        saveProfile()
    }

    func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            userDefaults.set(encoded, forKey: profileKey)
        }
    }

    func resetProfile() {
        self.profile = UserProfile(name: "User")
        saveProfile()
    }
}
