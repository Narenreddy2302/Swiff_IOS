//
//  BiometricAuthenticationService.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Biometric authentication service for Face ID and Touch ID
//

import LocalAuthentication
import Foundation
import Combine

// AGENT 5: Biometric authentication service for Face ID/Touch ID
@MainActor
class BiometricAuthenticationService: ObservableObject {
    static let shared = BiometricAuthenticationService()

    @Published var isAvailable: Bool = false
    @Published var biometricType: BiometricType = .none

    // AGENT 5: Biometric type enum
    enum BiometricType {
        case none
        case faceID
        case touchID

        var displayName: String {
            switch self {
            case .none: return "None"
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            }
        }

        var iconName: String {
            switch self {
            case .none: return "lock.fill"
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            }
        }
    }

    // AGENT 5: Authentication error enum
    enum AuthenticationError: LocalizedError {
        case notAvailable
        case notEnrolled
        case failed(String)
        case cancelled

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .notEnrolled:
                return "No biometric authentication is enrolled. Please set up Face ID or Touch ID in Settings"
            case .failed(let message):
                return message
            case .cancelled:
                return "Authentication was cancelled"
            }
        }
    }

    private init() {
        checkBiometricAvailability()
    }

    // AGENT 5: Check if biometrics are available on this device
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        // Determine biometric type
        if isAvailable {
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            case .none:
                biometricType = .none
                isAvailable = false
            @unknown default:
                biometricType = .none
                isAvailable = false
            }
        } else {
            biometricType = .none
        }
    }

    // AGENT 5: Authenticate using biometrics
    func authenticate(reason: String = "Unlock Swiff") async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                switch error.code {
                case LAError.biometryNotEnrolled.rawValue:
                    throw AuthenticationError.notEnrolled
                case LAError.biometryNotAvailable.rawValue:
                    throw AuthenticationError.notAvailable
                default:
                    throw AuthenticationError.failed(error.localizedDescription)
                }
            }
            throw AuthenticationError.notAvailable
        }

        // Perform authentication
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .systemCancel, .appCancel:
                throw AuthenticationError.cancelled
            case .biometryNotEnrolled:
                throw AuthenticationError.notEnrolled
            case .biometryNotAvailable:
                throw AuthenticationError.notAvailable
            default:
                throw AuthenticationError.failed(error.localizedDescription)
            }
        } catch {
            throw AuthenticationError.failed(error.localizedDescription)
        }
    }

    // AGENT 5: Request biometric permission (first time setup)
    func requestPermission() async throws -> Bool {
        // For biometrics, permission is implicit when user attempts to use it
        // We just need to check availability
        checkBiometricAvailability()

        if !isAvailable {
            throw AuthenticationError.notAvailable
        }

        // Trigger first authentication to establish permission
        return try await authenticate(reason: "Enable biometric authentication for Swiff")
    }
}

// AGENT 5: Mock PIN encryption helper (Phase 2 should use proper encryption)
class PINEncryptionHelper {
    static let shared = PINEncryptionHelper()

    private init() {}

    // AGENT 5: Encrypt PIN (MOCK - Phase 2 should implement proper encryption with Keychain)
    func encrypt(pin: String) -> String {
        // WARNING: This is a mock implementation
        // Phase 2 should use proper encryption with KeychainSwift or CryptoKit
        return "ENCRYPTED_\(pin)_\(Date().timeIntervalSince1970)"
    }

    // AGENT 5: Verify PIN (MOCK - Phase 2 should implement proper verification)
    func verify(pin: String, against encryptedPIN: String) -> Bool {
        // WARNING: This is a mock implementation
        // For now, just check if the encrypted PIN contains the actual PIN
        return encryptedPIN.contains(pin)
    }

    // AGENT 5: Decrypt PIN (MOCK - Phase 2 should implement proper decryption)
    func decrypt(encryptedPIN: String) -> String? {
        // WARNING: This is a mock implementation
        let components = encryptedPIN.components(separatedBy: "_")
        return components.count > 1 ? components[1] : nil
    }
}
