//
//  TransactionType.swift
//  Swiff IOS
//
//  Transaction type classification for feed display
//  Works alongside TransactionCategory for filtering
//

import Foundation

/// Transaction type for feed display and filtering
/// Describes the nature of a transaction (receive, send, payment, transfer, request)
enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case receive = "Receive"
    case send = "Send"
    case payment = "Payment"
    case transfer = "Transfer"
    case request = "Request"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String { rawValue }

    /// SF Symbol icon for the transaction type
    var icon: String {
        switch self {
        case .receive: return "arrow.down.left"
        case .send: return "arrow.up.right"
        case .payment: return "creditcard"
        case .transfer: return "arrow.left.arrow.right"
        case .request: return "clock.arrow.circlepath"
        }
    }

    /// Maps to FeedFilterTab for filtering
    var filterTab: FeedFilterTab {
        switch self {
        case .receive: return .income
        case .send: return .sent
        case .payment: return .sent
        case .transfer: return .transfer
        case .request: return .request
        }
    }
}

/// Filter tabs for the feed view
enum FeedFilterTab: String, CaseIterable, Identifiable {
    case all = "All"
    case income = "Income"
    case sent = "Sent"
    case request = "Request"
    case transfer = "Transfer"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String { rawValue }
}
