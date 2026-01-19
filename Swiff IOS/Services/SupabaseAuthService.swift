//
//  SupabaseAuthService.swift
//  Swiff IOS
//
//  Authentication service for Supabase email auth
//

import Combine
import Foundation
import Supabase

/// Service for handling Supabase authentication
@MainActor
final class SupabaseAuthService: ObservableObject {

    // MARK: - Singleton

    static let shared = SupabaseAuthService()

    // MARK: - Published Properties

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isEmailVerified = false
    @Published private(set) var isLoading = false
    @Published private(set) var isCheckingAuth = true
    @Published private(set) var currentUserProfile: SupabaseUserProfile?
    @Published private(set) var currentUserEmail: String?
    @Published var error: AuthError?

    // MARK: - Properties

    private let supabase = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Observe auth state from SupabaseService
        supabase.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else { return }

                self.isAuthenticated = user != nil
                self.currentUserEmail = user?.email

                if let user = user {
                    // Check email verification status
                    self.isEmailVerified = user.emailConfirmedAt != nil

                    Task {
                        await self.fetchUserProfile()
                        self.isCheckingAuth = false
                    }
                } else {
                    self.currentUserProfile = nil
                    self.isEmailVerified = false
                    self.isCheckingAuth = false
                }
            }
            .store(in: &cancellables)

        // Initial session check
        Task {
            await checkInitialSession()
        }
    }

    /// Check for existing session on app launch
    private func checkInitialSession() async {
        do {
            let session = try await supabase.client.auth.session
            let user = session.user

            await MainActor.run {
                self.isAuthenticated = true
                self.currentUserEmail = user.email
                self.isEmailVerified = user.emailConfirmedAt != nil
            }

            await fetchUserProfile()

            await MainActor.run {
                self.isCheckingAuth = false
            }
        } catch {
            // No valid session
            await MainActor.run {
                self.isAuthenticated = false
                self.isEmailVerified = false
                self.isCheckingAuth = false
            }
        }
    }

    // MARK: - Sign Up

    /// Sign up with email and password
    func signUp(
        email: String,
        password: String,
        name: String? = nil
    ) async throws {
        isLoading = true
        error = nil

        do {
            var metadata: [String: AnyJSON] = [:]
            if let name = name {
                metadata["name"] = .string(name)
            }

            let response = try await supabase.client.auth.signUp(
                email: email,
                password: password,
                data: metadata
            )

            // Check if email confirmation is required
            if response.session == nil {
                // Email confirmation required
                throw AuthError.emailConfirmationRequired
            }

            isLoading = false
        } catch let authError as AuthError {
            isLoading = false
            self.error = authError
            throw authError
        } catch {
            isLoading = false
            let wrappedError = AuthError.signUpFailed(error.localizedDescription)
            self.error = wrappedError
            throw wrappedError
        }
    }

    // MARK: - Sign In

    /// Sign in with email and password
    func signIn(
        email: String,
        password: String
    ) async throws {
        isLoading = true
        error = nil

        do {
            try await supabase.client.auth.signIn(
                email: email,
                password: password
            )

            isLoading = false
        } catch {
            isLoading = false
            let wrappedError = AuthError.signInFailed(error.localizedDescription)
            self.error = wrappedError
            throw wrappedError
        }
    }

    // MARK: - Sign Out

    /// Sign out the current user
    func signOut() async throws {
        isLoading = true
        error = nil

        do {
            try await supabase.client.auth.signOut()
            currentUserProfile = nil
            isLoading = false
        } catch {
            isLoading = false
            let wrappedError = AuthError.signOutFailed(error.localizedDescription)
            self.error = wrappedError
            throw wrappedError
        }
    }

    // MARK: - Password Reset

    /// Send password reset email
    func sendPasswordReset(email: String) async throws {
        isLoading = true
        error = nil

        do {
            try await supabase.client.auth.resetPasswordForEmail(email)
            isLoading = false
        } catch {
            isLoading = false
            let wrappedError = AuthError.passwordResetFailed(error.localizedDescription)
            self.error = wrappedError
            throw wrappedError
        }
    }

    /// Update password (after reset or while logged in)
    func updatePassword(newPassword: String) async throws {
        isLoading = true
        error = nil

        do {
            try await supabase.client.auth.update(user: UserAttributes(password: newPassword))
            isLoading = false
        } catch {
            isLoading = false
            let wrappedError = AuthError.passwordUpdateFailed(error.localizedDescription)
            self.error = wrappedError
            throw wrappedError
        }
    }

    // MARK: - User Profile

    /// Fetch the current user's profile from the database
    func fetchUserProfile() async {
        guard let userId = supabase.currentUser?.id else { return }

        do {
            let profiles: [SupabaseUserProfile] = try await supabase.client
                .from(SupabaseConfig.Tables.userProfiles)
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            currentUserProfile = profiles.first
        } catch {
            print("Failed to fetch user profile: \(error)")
        }
    }

    /// Update the current user's profile
    func updateProfile(
        name: String? = nil,
        phone: String? = nil,
        avatarType: String? = nil,
        avatarEmoji: String? = nil,
        avatarInitials: String? = nil,
        avatarColorIndex: Int? = nil
    ) async throws {
        guard let userId = supabase.currentUser?.id else {
            throw AuthError.notAuthenticated
        }

        isLoading = true
        error = nil

        do {
            var updates: [String: AnyJSON] = [:]

            if let name = name {
                updates["name"] = .string(name)
            }
            if let phone = phone {
                updates["phone"] = .string(phone)
            }
            if let avatarType = avatarType {
                updates["avatar_type"] = .string(avatarType)
            }
            if let avatarEmoji = avatarEmoji {
                updates["avatar_emoji"] = .string(avatarEmoji)
            }
            if let avatarInitials = avatarInitials {
                updates["avatar_initials"] = .string(avatarInitials)
            }
            if let avatarColorIndex = avatarColorIndex {
                updates["avatar_color_index"] = .integer(avatarColorIndex)
            }

            try await supabase.client
                .from(SupabaseConfig.Tables.userProfiles)
                .update(updates)
                .eq("id", value: userId.uuidString)
                .execute()

            // Refresh the profile
            await fetchUserProfile()

            isLoading = false
        } catch {
            isLoading = false
            let wrappedError = AuthError.profileUpdateFailed(error.localizedDescription)
            self.error = wrappedError
            throw wrappedError
        }
    }

    // MARK: - Session Management

    /// Check if there's a valid session
    func checkSession() async -> Bool {
        do {
            let session = try await supabase.client.auth.session
            return session.user.id != UUID()
        } catch {
            return false
        }
    }

    /// Refresh the current session
    func refreshSession() async throws {
        do {
            try await supabase.client.auth.refreshSession()
        } catch {
            throw AuthError.sessionRefreshFailed(error.localizedDescription)
        }
    }

    /// Get the current access token
    func getAccessToken() async throws -> String {
        do {
            let session = try await supabase.client.auth.session
            return session.accessToken
        } catch {
            throw AuthError.notAuthenticated
        }
    }

    // MARK: - Email Verification

    /// Resend verification email
    func resendVerificationEmail(email: String) async throws {
        do {
            try await supabase.client.auth.resend(
                email: email,
                type: .signup
            )
        } catch {
            throw AuthError.verificationEmailFailed(error.localizedDescription)
        }
    }

    /// Check and refresh email verification status
    func checkEmailVerification() async -> Bool {
        do {
            // Refresh the session to get updated user info
            try await supabase.client.auth.refreshSession()
            let session = try await supabase.client.auth.session
            let verified = session.user.emailConfirmedAt != nil

            await MainActor.run {
                self.isEmailVerified = verified
            }

            return verified
        } catch {
            return false
        }
    }
}

// MARK: - Auth Error Types

enum AuthError: LocalizedError, Identifiable {
    case notAuthenticated
    case emailConfirmationRequired
    case signUpFailed(String)
    case signInFailed(String)
    case signOutFailed(String)
    case passwordResetFailed(String)
    case passwordUpdateFailed(String)
    case profileUpdateFailed(String)
    case sessionRefreshFailed(String)
    case verificationEmailFailed(String)
    case invalidCredentials
    case networkError(String)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not signed in"
        case .emailConfirmationRequired:
            return "Please check your email to confirm your account"
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .passwordResetFailed(let message):
            return "Password reset failed: \(message)"
        case .passwordUpdateFailed(let message):
            return "Password update failed: \(message)"
        case .profileUpdateFailed(let message):
            return "Profile update failed: \(message)"
        case .sessionRefreshFailed(let message):
            return "Session refresh failed: \(message)"
        case .verificationEmailFailed(let message):
            return "Failed to send verification email: \(message)"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - User Profile Model

/// Supabase user profile model
struct SupabaseUserProfile: Codable, Identifiable, Sendable {
    let id: UUID
    let email: String
    var name: String
    var phone: String?
    var avatarType: String?
    var avatarEmoji: String?
    var avatarInitials: String?
    var avatarColorIndex: Int?
    var defaultCurrency: String?
    var timezone: String?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncVersion: Int

    enum CodingKeys: String, CodingKey {
        case id, email, name, phone
        case avatarType = "avatar_type"
        case avatarEmoji = "avatar_emoji"
        case avatarInitials = "avatar_initials"
        case avatarColorIndex = "avatar_color_index"
        case defaultCurrency = "default_currency"
        case timezone
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }

    /// Computed initials from name
    var computedInitials: String {
        if let initials = avatarInitials, !initials.isEmpty {
            return initials
        }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
