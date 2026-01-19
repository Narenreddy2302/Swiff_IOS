//
//  CardContext.swift
//  Swiff IOS
//
//  Context enum and button style for Transaction Card components
//

import SwiftUI

// MARK: - Card Context

/// Determines which icon to display based on where the card is shown
enum CardContext {
    case feed           // Use transaction category icon
    case person         // Use person.fill icon
    case group          // Use person.3.fill icon
    case subscription   // Use subscription's brand icon

    func icon(for transaction: Transaction, subscription: Subscription? = nil) -> String {
        switch self {
        case .feed:
            return transaction.category.icon
        case .person:
            return "person.fill"
        case .group:
            return "person.3.fill"
        case .subscription:
            return subscription?.icon ?? "creditcard.fill"
        }
    }

    func color(for transaction: Transaction, subscription: Subscription? = nil) -> Color {
        switch self {
        case .feed:
            return transaction.category.color
        case .person:
            return .wisePurple
        case .group:
            return .wiseBlue
        case .subscription:
            if let sub = subscription {
                return Color(hexString: sub.color)
            }
            return .wiseBlue
        }
    }
}

// MARK: - Card Button Style

/// Custom button style with press animation and haptic feedback
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
    }
}
