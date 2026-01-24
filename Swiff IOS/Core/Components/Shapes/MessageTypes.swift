//
//  MessageTypes.swift
//  Swiff IOS
//
//  Created by Agent on 1/19/26.
//

import Foundation

// MARK: - Message Bubble Direction

public enum iMessageBubbleDirection: Sendable, Equatable {
    case incoming  // Left-aligned (gray) - other person
    case outgoing  // Right-aligned (blue) - current user
    case center  // Centered (system messages)
}
