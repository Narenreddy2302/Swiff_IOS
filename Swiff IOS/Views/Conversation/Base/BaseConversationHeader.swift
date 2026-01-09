//
//  BaseConversationHeader.swift
//  Swiff IOS
//
//  Unified base component for all compact conversation headers
//  Following Apple HIG: 44pt minimum tap targets, consistent spacing
//

import SwiftUI

// MARK: - Configuration

/// Configuration for compact conversation headers
struct CompactHeaderConfiguration {
    var showBackButton: Bool = true
    var showDivider: Bool = true
    var minHeight: CGFloat = Theme.Metrics.headerHeight
}

// MARK: - Base Header

/// Unified base component for all compact conversation headers.
/// Use this as the foundation for Person, Contact, Group, and Subscription headers.
///
/// Example usage:
/// ```swift
/// BaseConversationHeader(
///     onBack: { dismiss() },
///     leading: { AvatarView(person: person, size: .medium) },
///     title: { HeaderTitleView(title: person.name, subtitle: "Balance info") },
///     trailing: { Button("Edit") { } }
/// )
/// ```
struct BaseConversationHeader<Leading: View, Title: View, Trailing: View>: View {
    let configuration: CompactHeaderConfiguration
    let leadingContent: () -> Leading
    let titleContent: () -> Title
    let trailingContent: () -> Trailing

    var onBack: (() -> Void)?

    init(
        configuration: CompactHeaderConfiguration = .init(),
        onBack: (() -> Void)? = nil,
        @ViewBuilder leading: @escaping () -> Leading = { EmptyView() as! Leading },
        @ViewBuilder title: @escaping () -> Title,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() as! Trailing }
    ) {
        self.configuration = configuration
        self.onBack = onBack
        self.leadingContent = leading
        self.titleContent = title
        self.trailingContent = trailing
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Metrics.headerContentSpacing) {
                // Back button (optional)
                if let onBack = onBack, configuration.showBackButton {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .navigationButtonStyle()
                    }
                    .accessibilityLabel("Back")
                    .accessibilityHint("Double tap to go back")
                }

                // Leading content (avatar)
                leadingContent()

                // Title content (name + subtitle)
                HStack(spacing: Theme.Metrics.headerAvatarSpacing) {
                    titleContent()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Trailing content (actions)
                trailingContent()
            }
            .padding(.horizontal, Theme.Metrics.headerPaddingH)
            .padding(.vertical, Theme.Metrics.headerPaddingV)
            .frame(minHeight: configuration.minHeight)
            .background(.ultraThinMaterial)

            if configuration.showDivider {
                Divider()
            }
        }
    }
}

// MARK: - Convenience Initializers

extension BaseConversationHeader where Leading == EmptyView {
    /// Initialize without leading content
    init(
        configuration: CompactHeaderConfiguration = .init(),
        onBack: (() -> Void)? = nil,
        @ViewBuilder title: @escaping () -> Title,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() as! Trailing }
    ) {
        self.configuration = configuration
        self.onBack = onBack
        self.leadingContent = { EmptyView() }
        self.titleContent = title
        self.trailingContent = trailing
    }
}

extension BaseConversationHeader where Trailing == EmptyView {
    /// Initialize without trailing content
    init(
        configuration: CompactHeaderConfiguration = .init(),
        onBack: (() -> Void)? = nil,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder title: @escaping () -> Title
    ) {
        self.configuration = configuration
        self.onBack = onBack
        self.leadingContent = leading
        self.titleContent = title
        self.trailingContent = { EmptyView() }
    }
}

// MARK: - Preview

#Preview("Base Header - Full") {
    BaseConversationHeader(
        onBack: {},
        leading: {
            Circle()
                .fill(Color.wiseBrightGreen)
                .frame(width: Theme.Metrics.avatarCompact, height: Theme.Metrics.avatarCompact)
        },
        title: {
            VStack(alignment: .leading, spacing: 2) {
                Text("John Doe")
                    .font(Theme.Fonts.headerTitle)
                    .foregroundColor(.wisePrimaryText)
                Text("Subtitle text")
                    .font(Theme.Fonts.headerSubtitle)
                    .foregroundColor(.wiseSecondaryText)
            }
        },
        trailing: {
            Button("Edit") {}
                .textActionButtonStyle()
        }
    )
    .background(Color.wiseBackground)
}

#Preview("Base Header - No Back Button") {
    BaseConversationHeader(
        configuration: .init(showBackButton: false),
        leading: {
            Circle()
                .fill(Color.wiseAccentBlue)
                .frame(width: Theme.Metrics.avatarCompact, height: Theme.Metrics.avatarCompact)
        },
        title: {
            Text("Header Title")
                .font(Theme.Fonts.headerTitle)
                .foregroundColor(.wisePrimaryText)
        }
    )
    .background(Color.wiseBackground)
}
