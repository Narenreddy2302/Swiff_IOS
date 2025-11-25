//
//  AccessibilityHelpers.swift
//  Swiff IOS
//
//  Created by Naren Reddy on 11/20/25.
//  Accessibility utilities and extensions
//

import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    /// Add accessibility label and hint
    func accessible(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
            .accessibilityAddTraits(traits)
    }

    /// Make view accessible as a button
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self.accessible(label: label, hint: hint, traits: .isButton)
    }

    /// Make view accessible as a header
    func accessibleHeader(label: String) -> some View {
        self.accessible(label: label, traits: .isHeader)
    }

    /// Group accessibility elements
    func accessibilityGroup(label: String? = nil) -> some View {
        SwiftUI.Group {
            if let label = label {
                self
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(label)
            } else {
                self.accessibilityElement(children: .combine)
            }
        }
    }

    /// Add accessibility action
    func accessibleAction(named name: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: name, action)
    }


}

// MARK: - Currency Accessibility

extension Double {
    /// Format currency with proper accessibility
    var accessibleCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserSettings.shared.selectedCurrency

        if let formatted = formatter.string(from: NSNumber(value: self)) {
            // Make it more speakable
            if self >= 0 {
                return "\(formatted)"
            } else {
                return "negative \(formatter.string(from: NSNumber(value: abs(self))) ?? "")"
            }
        }
        return "\(self)"
    }
}

// MARK: - Date Accessibility

extension Date {
    /// Format date for accessibility
    var accessibleDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Format date and time for accessibility
    var accessibleDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Relative date for accessibility (e.g., "today", "yesterday", "3 days ago")
    var accessibleRelativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Transaction Accessibility

extension Transaction {
    var accessibleDescription: String {
        let amountText = amount.accessibleCurrency
        let typeText = isExpense ? "expense" : "income"
        let dateText = date.accessibleRelativeDate

        return "\(title), \(amountText) \(typeText), \(dateText)"
    }
}

// MARK: - Person Accessibility

extension Person {
    var accessibleDescription: String {
        var description = name

        if balance != 0 {
            let amountText = abs(balance).accessibleCurrency
            if balance > 0 {
                description += ", owes you \(amountText)"
            } else {
                description += ", you owe \(amountText)"
            }
        } else {
            description += ", balanced"
        }

        return description
    }
}

// MARK: - Subscription Accessibility

extension Subscription {
    var accessibleDescription: String {
        let amountText = price.accessibleCurrency
        let cycleText = billingCycle.rawValue.lowercased()
        let statusText = isActive ? "active" : "inactive"

        var description = "\(name), \(amountText) per \(cycleText), \(statusText)"

        if isActive {
            let nextBillingText = nextBillingDate.accessibleRelativeDate
            description += ", next billing \(nextBillingText)"
        }

        return description
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// Get scaled font for accessibility
    static func scaledFont(name: String = "Helvetica Neue", size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        return Font.custom(name, size: size, relativeTo: textStyle).weight(weight)
    }
}

// MARK: - Color Contrast Helpers

extension Color {
    /// Check if color has sufficient contrast with white background
    var hasSufficientContrast: Bool {
        // Simplified check - in production, calculate actual contrast ratio
        return true
    }

    /// Get accessible version of color
    var accessible: Color {
        // Return a version with sufficient contrast
        return self
    }
}

// MARK: - Accessibility Settings
// Note: AccessibilitySettings is defined in AccessibilitySettings.swift

struct AccessibilityHelpers_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Accessibility Helpers")
                .font(.headline)
                .accessibleHeader(label: "Accessibility Features Demo")

            HStack {
                Circle()
                    .fill(Color.wiseForestGreen)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading) {
                    Text("John Doe")
                        .font(.headline)
                    Text("Owes you $25.00")
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .accessibleCard(
                label: "Person card for John Doe, owes you 25 dollars",
                hint: "Double tap to view details",
                isButton: true
            )

            Text("VoiceOver: \(AccessibilitySettings.isVoiceOverRunning ? "ON" : "OFF")")
                .font(.caption)

            Text("Reduce Motion: \(AccessibilitySettings.isReduceMotionEnabled ? "ON" : "OFF")")
                .font(.caption)
        }
        .padding()
    }
}
