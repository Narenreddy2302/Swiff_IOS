//
//  QuickActionButton.swift
//  Swiff IOS
//
//  Inline action buttons for conversation bubbles
//  Used for Settle, Remind, View Details actions
//

import SwiftUI

// MARK: - Quick Action Style

enum QuickActionStyle {
    case primary  // Green background (settle, confirm)
    case secondary  // Gray background (remind, view)
    case destructive  // Red background (delete, cancel)
    case outline  // Border only

    var backgroundColor: Color {
        switch self {
        case .primary:
            return Color.wiseBrightGreen.opacity(0.15)
        case .secondary:
            return Color.wiseBorder.opacity(0.3)
        case .destructive:
            return Color.wiseError.opacity(0.15)
        case .outline:
            return Color.clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary:
            return Color.wiseBrightGreen
        case .secondary:
            return Color.wiseSecondaryText
        case .destructive:
            return Color.wiseError
        case .outline:
            return Color.wisePrimaryText
        }
    }

    var borderColor: Color {
        switch self {
        case .outline:
            return Color.wiseBorder
        default:
            return Color.clear
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    var icon: String?
    var style: QuickActionStyle = .secondary
    var isCompact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(isCompact ? Theme.Fonts.badgeCompact : Theme.Fonts.badgeText)
                }

                Text(title)
                    .font(isCompact ? Theme.Fonts.badgeText : Theme.Fonts.labelLarge)
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, isCompact ? 10 : 14)
            .padding(.vertical, isCompact ? 6 : 8)
            .background(style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: isCompact ? 14 : 16)  // More rounded
                    .stroke(style.borderColor, lineWidth: 1)
            )
            .clipShape(Capsule())  // Capsule shape for more modern look
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Quick Action Button Group

struct QuickActionButtonGroup: View {
    let buttons: [QuickActionConfig]
    var alignment: HorizontalAlignment = .trailing
    var spacing: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            if alignment == .trailing {
                Spacer()
            }

            ForEach(buttons) { config in
                QuickActionButton(
                    title: config.title,
                    icon: config.icon,
                    style: config.style,
                    isCompact: config.isCompact,
                    action: config.action
                )
            }

            if alignment == .leading {
                Spacer()
            }
        }
    }
}

// MARK: - Quick Action Config

struct QuickActionConfig: Identifiable {
    let id = UUID()
    let title: String
    var icon: String?
    var style: QuickActionStyle = .secondary
    var isCompact: Bool = false
    let action: () -> Void
}

// MARK: - Preset Quick Action Buttons

extension QuickActionButton {
    /// Settle action button (green)
    static func settle(amount: Double? = nil, action: @escaping () -> Void) -> QuickActionButton {
        let title = amount.map { "Settle \(formatCurrency($0))" } ?? "Settle"
        return QuickActionButton(
            title: title,
            icon: "checkmark.circle.fill",
            style: .primary,
            action: action
        )
    }

    /// Remind action button (secondary)
    static func remind(action: @escaping () -> Void) -> QuickActionButton {
        QuickActionButton(
            title: "Remind",
            icon: "bell.fill",
            style: .secondary,
            action: action
        )
    }

    /// View details action button (outline)
    static func viewDetails(action: @escaping () -> Void) -> QuickActionButton {
        QuickActionButton(
            title: "Details",
            icon: "chevron.right",
            style: .outline,
            action: action
        )
    }

    /// Cancel action button (destructive)
    static func cancel(action: @escaping () -> Void) -> QuickActionButton {
        QuickActionButton(
            title: "Cancel",
            icon: "xmark.circle.fill",
            style: .destructive,
            action: action
        )
    }

    private static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// MARK: - Preview

#Preview("Quick Action Buttons") {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 12) {
            Text("Primary Actions")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 8) {
                QuickActionButton.settle(amount: 45.00) {}
                QuickActionButton(
                    title: "Pay Now",
                    icon: "dollarsign.circle.fill",
                    style: .primary
                ) {}
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Secondary Actions")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 8) {
                QuickActionButton.remind {}
                QuickActionButton(
                    title: "Edit",
                    icon: "pencil",
                    style: .secondary
                ) {}
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Outline Actions")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 8) {
                QuickActionButton.viewDetails {}
                QuickActionButton(
                    title: "More",
                    icon: "ellipsis",
                    style: .outline
                ) {}
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Destructive Actions")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 8) {
                QuickActionButton.cancel {}
                QuickActionButton(
                    title: "Delete",
                    icon: "trash.fill",
                    style: .destructive
                ) {}
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Compact Buttons")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            HStack(spacing: 6) {
                QuickActionButton(
                    title: "Settle",
                    icon: "checkmark",
                    style: .primary,
                    isCompact: true
                ) {}
                QuickActionButton(
                    title: "Remind",
                    icon: "bell",
                    style: .secondary,
                    isCompact: true
                ) {}
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Button Group (Right Aligned)")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)

            QuickActionButtonGroup(buttons: [
                QuickActionConfig(title: "Settle", icon: "checkmark", style: .primary) {},
                QuickActionConfig(title: "Remind", icon: "bell", style: .secondary) {},
            ])
        }

        Spacer()
    }
    .padding(16)
    .background(Color.wiseBackground)
}
