//
//  PaymentStatus.swift
//  Swiff IOS
//
//  Created for Page 2 Task Implementation
//  Payment status tracking for transactions
//

import SwiftUI

// MARK: - Payment Status

enum PaymentStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case completed = "Completed"
    case failed = "Failed"
    case refunded = "Refunded"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .pending: return "clock.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .refunded: return "arrow.uturn.backward.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .wiseWarning // Adaptive yellow/orange
        case .completed: return .wiseSuccess // Adaptive green
        case .failed: return .wiseError // Adaptive red
        case .refunded: return .wiseInfo // Adaptive blue
        case .cancelled: return .wiseMidGray // Gray
        }
    }

    var badgeBackgroundColor: Color {
        color.opacity(0.15)
    }
}
