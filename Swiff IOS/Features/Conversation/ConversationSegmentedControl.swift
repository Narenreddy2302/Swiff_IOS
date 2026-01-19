//
//  ConversationSegmentedControl.swift
//  Swiff IOS
//
//  Custom segmented control for conversation views
//  Three styles available for different contexts
//

import SwiftUI

// MARK: - Segmented Control Usage Guide
///
/// This file contains THREE segmented control styles for different contexts:
///
/// 1. `ConversationSegmentedControl` (Background Style)
///    - USE FOR: Primary navigation within a view
///    - CONTEXT: Top-level tab switching (e.g., Transactions | Summary)
///    - STYLE: Filled background with card-style selected state
///
/// 2. `UnderlineSegmentedControl`
///    - USE FOR: Secondary navigation or filtering
///    - CONTEXT: Content filtering within a section
///    - STYLE: Underline indicator (bright green, 2pt), subtle appearance
///
/// 3. `PillSegmentedControl` (Apple Native Style - Recommended Default)
///    - USE FOR: iOS-native look and feel contexts
///    - CONTEXT: Settings, forms, or when matching iOS system style
///    - STYLE: Pill with shadow, closest to UISegmentedControl
///
/// Selection Guide:
/// - Use PillSegmentedControl as default for new features (Apple HIG compliant)
/// - Use ConversationSegmentedControl for chat/conversation contexts
/// - Use UnderlineSegmentedControl for dense filtering scenarios

// MARK: - Conversation Tab Protocol

protocol ConversationTabProtocol: Hashable, CaseIterable, RawRepresentable
where RawValue == String {}

// MARK: - Conversation Segmented Control

struct ConversationSegmentedControl<Tab: ConversationTabProtocol>: View {
    @Binding var selectedTab: Tab
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(Color.wiseBorder.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private func tabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            Text(tab.rawValue)
                .font(.spotifyLabelMedium)
                .foregroundColor(selectedTab == tab ? .wisePrimaryText : .wiseSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        if selectedTab == tab {
                            Color.wiseCardBackground
                                .cornerRadius(10)
                                .matchedGeometryEffect(id: "selectedTab", in: namespace)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Underline Style Segmented Control

struct UnderlineSegmentedControl<Tab: ConversationTabProtocol>: View {
    @Binding var selectedTab: Tab
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                underlineTabButton(for: tab)
            }
        }
        .padding(.horizontal, 16)
    }

    private func underlineTabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 8) {
                Text(tab.rawValue)
                    .font(.spotifyBodyMedium)
                    .fontWeight(selectedTab == tab ? .semibold : .medium)
                    .foregroundColor(selectedTab == tab ? .wisePrimaryText : .wiseSecondaryText)
                    .frame(maxWidth: .infinity)

                // Underline indicator
                if selectedTab == tab {
                    Rectangle()
                        .fill(Color.wiseBrightGreen)
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "underline", in: namespace)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pill Style Segmented Control (Reference Design Match)

struct PillSegmentedControl<Tab: ConversationTabProtocol>: View {
    @Binding var selectedTab: Tab
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                pillTabButton(for: tab)
            }
        }
        .padding(2)
        .background(Color(.systemGroupedBackground))  // Native-like background
        .cornerRadius(20)
        .padding(.horizontal, 16)
    }

    private func pillTabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            Text(tab.rawValue)
                .font(selectedTab == tab ? Theme.Fonts.labelLarge : Theme.Fonts.bodyMedium)
                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        if selectedTab == tab {
                            Color(.systemBackground)
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
                                .matchedGeometryEffect(id: "pill", in: namespace)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sample Tab Types for Preview

enum SamplePersonTab: String, ConversationTabProtocol, CaseIterable {
    case transactions = "Transactions"
    case summary = "Summary"
}

enum SampleGroupTab: String, ConversationTabProtocol, CaseIterable {
    case activity = "Activity"
    case balances = "Balances"
    case members = "Members"
}

enum SampleSubscriptionTab: String, ConversationTabProtocol, CaseIterable {
    case timeline = "Timeline"
    case details = "Details"
}

// MARK: - Preview

#Preview("Segmented Controls") {
    VStack(spacing: 32) {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Style")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, 16)

            ConversationSegmentedControl(selectedTab: .constant(SamplePersonTab.transactions))
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Underline Style")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, 16)

            UnderlineSegmentedControl(selectedTab: .constant(SampleGroupTab.activity))
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Pill Style (Reference Match)")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, 16)

            PillSegmentedControl(selectedTab: .constant(SamplePersonTab.transactions))
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Three Tabs")
                .font(.spotifyLabelMedium)
                .foregroundColor(.wiseSecondaryText)
                .padding(.horizontal, 16)

            PillSegmentedControl(selectedTab: .constant(SampleGroupTab.activity))
        }

        Spacer()
    }
    .padding(.top, 32)
    .background(Color.wiseBackground)
}
