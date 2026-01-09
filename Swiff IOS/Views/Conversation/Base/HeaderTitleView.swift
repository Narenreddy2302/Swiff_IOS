//
//  HeaderTitleView.swift
//  Swiff IOS
//
//  Reusable title + subtitle component for conversation headers
//

import SwiftUI

// MARK: - Header Title View

/// Reusable title component for conversation headers.
/// Supports title, optional subtitle, and optional accessory view.
///
/// Example usage:
/// ```swift
/// HeaderTitleView(
///     title: "John Doe",
///     subtitle: "Owes you $25.00"
/// )
/// ```
struct HeaderTitleView: View {
    let title: String
    var subtitle: String?
    var subtitleColor: Color = .wiseSecondaryText
    var accessoryView: AnyView?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.Fonts.headerTitle)
                .foregroundColor(.wisePrimaryText)
                .lineLimit(1)

            if let subtitle = subtitle {
                HStack(spacing: 6) {
                    Text(subtitle)
                        .font(Theme.Fonts.headerSubtitle)
                        .foregroundColor(subtitleColor)

                    if let accessory = accessoryView {
                        accessory
                    }
                }
            } else if let accessory = accessoryView {
                accessory
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Convenience Initializers

extension HeaderTitleView {
    /// Initialize with title only
    init(title: String) {
        self.title = title
        self.subtitle = nil
        self.subtitleColor = .wiseSecondaryText
        self.accessoryView = nil
    }

    /// Initialize with title and subtitle
    init(title: String, subtitle: String, subtitleColor: Color = .wiseSecondaryText) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleColor = subtitleColor
        self.accessoryView = nil
    }

    /// Initialize with title and accessory view
    init<Accessory: View>(title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.subtitle = nil
        self.subtitleColor = .wiseSecondaryText
        self.accessoryView = AnyView(accessory())
    }

    /// Initialize with title, subtitle, and accessory view
    init<Accessory: View>(
        title: String,
        subtitle: String,
        subtitleColor: Color = .wiseSecondaryText,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleColor = subtitleColor
        self.accessoryView = AnyView(accessory())
    }
}

// MARK: - Preview

#Preview("Header Title - Full") {
    VStack(spacing: 24) {
        HeaderTitleView(title: "John Doe")
            .padding()
            .background(Color.wiseCardBackground)

        HeaderTitleView(
            title: "Jane Smith",
            subtitle: "Owes you $125.00"
        )
        .padding()
        .background(Color.wiseCardBackground)

        HeaderTitleView(
            title: "Bob Johnson",
            subtitle: "You owe $50.00",
            subtitleColor: .wiseError
        )
        .padding()
        .background(Color.wiseCardBackground)

        HeaderTitleView(
            title: "Alice Brown",
            subtitle: "On Swiff"
        ) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.wiseBrightGreen)
                .font(.caption)
        }
        .padding()
        .background(Color.wiseCardBackground)
    }
    .padding()
    .background(Color.wiseBackground)
}
