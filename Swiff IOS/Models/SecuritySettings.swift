//
//  SecuritySettings.swift
//  Swiff IOS
//
//  Created by Agent 5 on 11/21/25.
//  Security settings models for biometric authentication, PIN, and auto-lock
//

import Foundation
import Combine

// AGENT 5: Security settings model for storing security preferences
struct SecuritySettings: Codable {
    var biometricAuthEnabled: Bool
    var pinLockEnabled: Bool
    var autoLockEnabled: Bool
    var autoLockDuration: AutoLockDuration
    var encryptedPIN: String?

    // AGENT 5: Auto-lock duration options
    enum AutoLockDuration: Int, Codable, CaseIterable {
        case oneMinute = 60
        case fiveMinutes = 300
        case fifteenMinutes = 900
        case thirtyMinutes = 1800
        case never = 0

        var displayName: String {
            switch self {
            case .oneMinute: return "1 Minute"
            case .fiveMinutes: return "5 Minutes"
            case .fifteenMinutes: return "15 Minutes"
            case .thirtyMinutes: return "30 Minutes"
            case .never: return "Never"
            }
        }
    }

    init(
        biometricAuthEnabled: Bool = false,
        pinLockEnabled: Bool = false,
        autoLockEnabled: Bool = false,
        autoLockDuration: AutoLockDuration = .never,
        encryptedPIN: String? = nil
    ) {
        self.biometricAuthEnabled = biometricAuthEnabled
        self.pinLockEnabled = pinLockEnabled
        self.autoLockEnabled = autoLockEnabled
        self.autoLockDuration = autoLockDuration
        self.encryptedPIN = encryptedPIN
    }
}
