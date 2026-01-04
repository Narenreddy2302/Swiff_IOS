//
//  ConversationSegmentedControl.swift
//  Swiff IOS
//
//  Custom segmented control for conversation views
//  Matches the reference design with underline indicator
//

import SwiftUI

// MARK: - Conversation Tab Protocol

protocol ConversationTabProtocol: Hashable, CaseIterable, RawRepresentable where RawValue == String {}

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
        HStack(spacing: 8) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                pillTabButton(for: tab)
            }
        }
        .padding(4)
        .background(Color.wiseBorder.opacity(0.3))
        .cornerRadius(25)
        .padding(.horizontal, 16)
    }

    private func pillTabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            Text(tab.rawValue)
                .font(.spotifyBodyMedium)
                .fontWeight(selectedTab == tab ? .semibold : .medium)
                .foregroundColor(selectedTab == tab ? .wisePrimaryText : .wiseSecondaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        if selectedTab == tab {
                            Color.wiseCardBackground
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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
