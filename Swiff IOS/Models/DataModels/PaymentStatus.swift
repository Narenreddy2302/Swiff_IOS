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
        case .pending: return Color(red: 1.0, green: 0.800, blue: 0.0) // Yellow
        case .completed: return Color(red: 0.624, green: 0.910, blue: 0.439) // wiseBrightGreen
        case .failed: return Color(red: 0.894, green: 0.129, blue: 0.192) // wiseError
        case .refunded: return Color(red: 0.0, green: 0.725, blue: 1.0) // wiseBlue
        case .cancelled: return Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
        }
    }

    var badgeBackgroundColor: Color {
        color.opacity(0.15)
    }
}
