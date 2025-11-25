//
//  AccessibilityAnnouncer.swift
//  Swiff IOS
//
//  Created by Agent 11 on 11/21/25.
//  VoiceOver announcement utility
//

import UIKit
import SwiftUI
import Combine

// MARK: - Accessibility Announcer

class AccessibilityAnnouncer {
    static let shared = AccessibilityAnnouncer()

    private init() {}

    enum AnnouncementPriority {
        case low
        case announcement
        case high

        var notification: UIAccessibility.Notification {
            switch self {
            case .low:
                return .announcement
            case .announcement:
                return .announcement
            case .high:
                return .screenChanged
            }
        }
    }

    /// Announce a message to VoiceOver users
    func announce(_ message: String, priority: AnnouncementPriority = .announcement) {
        guard AccessibilitySettings.isVoiceOverRunning else { return }

        DispatchQueue.main.async {
            UIAccessibility.post(notification: priority.notification, argument: message)
        }
    }

    /// Announce that a screen has changed
    func announceScreenChange(_ message: String? = nil) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .screenChanged, argument: message)
        }
    }

    /// Announce that layout has changed
    func announceLayoutChange(_ message: String? = nil) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: message)
        }
    }

    /// Announce that a page has scrolled
    func announcePageScrolled(_ message: String) {
        announce(message, priority: .low)
    }

    /// Announce an error
    func announceError(_ error: String) {
        announce("Error: \(error)", priority: .high)
    }

    /// Announce success
    func announceSuccess(_ message: String) {
        announce("Success: \(message)", priority: .announcement)
    }
}

// MARK: - View Extension

extension View {
    /// Announce a message when this view appears
    func announceOnAppear(_ message: String, priority: AccessibilityAnnouncer.AnnouncementPriority = .announcement) -> some View {
        self.onAppear {
            AccessibilityAnnouncer.shared.announce(message, priority: priority)
        }
    }
}
