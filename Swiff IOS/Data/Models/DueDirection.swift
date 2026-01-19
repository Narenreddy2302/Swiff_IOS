//
//  DueDirection.swift
//  Swiff IOS
//
//  Created by Claude Code on 1/8/26.
//  Direction of a due/IOU transaction
//

import Foundation

/// Direction of a due transaction - whether someone owes you or you owe them
enum DueDirection: String, CaseIterable, Codable, Sendable {
    case theyOweMe = "they_owe_me"
    case iOweThem = "i_owe_them"

    /// Display text for the direction
    var displayText: String {
        switch self {
        case .theyOweMe: return "They owe me"
        case .iOweThem: return "I owe them"
        }
    }

    /// Short description for the balance display
    var balanceLabel: String {
        switch self {
        case .theyOweMe: return "owes you"
        case .iOweThem: return "you owe"
        }
    }

    /// Icon for the direction
    var icon: String {
        switch self {
        case .theyOweMe: return "arrow.down.circle.fill"
        case .iOweThem: return "arrow.up.circle.fill"
        }
    }

    /// Whether this direction results in positive balance (they owe you)
    var isPositiveBalance: Bool {
        switch self {
        case .theyOweMe: return true
        case .iOweThem: return false
        }
    }
}
