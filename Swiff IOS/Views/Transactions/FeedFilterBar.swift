//
//  FeedFilterBar.swift
//  Swiff IOS
//
//  Redesigned filter bar with independent pill buttons
//  Horizontal scrollable layout: All, Income, Sent, Request, Transfer
//

import SwiftUI

// MARK: - Feed Filter Bar

struct FeedFilterBar: View {
    @Binding var selectedTab: FeedFilterTab
    var onSelect: ((FeedFilterTab) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FeedFilterTab.allCases) { tab in
                    FilterPillButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        HapticManager.shared.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                        onSelect?(tab)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Filter Pill Button

struct FilterPillButton: View {
    let tab: FeedFilterTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tab.rawValue)
                .font(.spotifyLabelMedium)
                .foregroundColor(isSelected ? Theme.Colors.textOnPrimary : Theme.Colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.Colors.brandPrimary : Theme.Colors.border)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(tab.rawValue) filter")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("FeedFilterBar - All Selected") {
    ZStack {
        Color.white.ignoresSafeArea()
        VStack {
            FeedFilterBar(selectedTab: .constant(.all))
            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview("FeedFilterBar - Income Selected") {
    ZStack {
        Color.white.ignoresSafeArea()
        VStack {
            FeedFilterBar(selectedTab: .constant(.income))
            Spacer()
        }
        .padding(.top, 20)
    }
}
